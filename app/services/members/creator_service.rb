# frozen_string_literal: true

module Members
  # This class serves as more of an app-wide way we add/create members
  # All roads to add members should take this path.
  class CreatorService
    class << self
      def parsed_access_level(access_level)
        access_levels.fetch(access_level) { access_level.to_i }
      end

      def access_levels
        Gitlab::Access.sym_options_with_owner
      end

      # Add members to sources with passed access option
      #
      # access can be an integer representing a access code
      # or symbol like :maintainer representing role
      #
      # Ex.
      #   add_members(
      #     sources,
      #     user_ids,
      #     Member::MAINTAINER
      #   )
      #
      #   add_members(
      #     sources,
      #     user_ids,
      #     :maintainer
      #   )
      #
      # @param sources [Group, Project, Array<Group>, Array<Project>, Group::ActiveRecord_Relation,
      # Project::ActiveRecord_Relation] - Can't be an array of source ids because we don't know the type of source.
      # @return Array<Member>
      def add_members(sources, invitees, access_level, **args)
        return [] unless invitees.present?

        sources = Array.wrap(sources) if sources.is_a?(ApplicationRecord) # For single source

        Gitlab::Database::QueryAnalyzers::PreventCrossDatabaseModification.temporary_ignore_tables_in_transaction(
          %w[users user_preferences user_details emails identities], url: 'https://gitlab.com/gitlab-org/gitlab/-/issues/424276'
        ) do
          Member.transaction do
            sources.flat_map do |source|
              # If this user is attempting to manage Owner members and doesn't have permission, do not allow
              current_user = args[:current_user]
              next [] if managing_owners?(current_user, access_level) && cannot_manage_owners?(source, current_user)

              emails, users, existing_members, users_by_emails = parse_users_list(source, invitees)

              common_arguments = {
                source: source,
                access_level: access_level,
                existing_members: existing_members,
                users_by_emails: users_by_emails
              }.merge(parsed_args(args))

              build_members(emails, users, common_arguments)
            end
          end
        end
      end

      def build_members(emails, users, common_arguments)
        members = emails.map do |email|
          new(invitee: email, builder: InviteMemberBuilder, **common_arguments).execute
        end

        members += users.map do |user|
          new(invitee: user, **common_arguments).execute
        end

        members
      end

      def add_member(source, invitee, access_level, **args)
        add_members(source, [invitee], access_level, **args).first
      end

      private

      def parsed_args(args)
        {
          current_user: args[:current_user],
          expires_at: args[:expires_at],
          ldap: args[:ldap]
        }
      end

      def managing_owners?(current_user, access_level)
        current_user && Gitlab::Access.sym_options_with_owner[access_level] == Gitlab::Access::OWNER
      end

      def parse_users_list(source, list)
        emails = []
        user_ids = []
        users = []
        existing_members = {}

        list.each do |item|
          case item
          when User
            users << item
          when Integer
            user_ids << item
          when /\A\d+\Z/
            user_ids << item.to_i
          when Devise.email_regexp
            emails << item
          end
        end

        # the below will automatically discard invalid user_ids
        users.concat(User.id_in(user_ids)) if user_ids.present?
        # de-duplicate just in case as there is no controlling if user records and ids are sent multiple times
        users.uniq!

        # We need to downcase any input of emails here for our caching so that emails sent in with uppercase
        # are also found since all emails are stored in users, emails tables downcase. user.private_commit_emails are
        # not though, so we'll never cache those I guess at this layer for now.
        # Since there is possibility of duplicate values once we downcase, we'll de-duplicate.
        # Uniq call here has no current testable impact as it will get the same parsed_emails
        # result without it, but it merely helps it do a bit less work.
        case_insensitive_emails = emails.map(&:downcase).uniq
        users_by_emails = source.users_by_emails(case_insensitive_emails) # preloads our request store for all emails
        # in case emails belong to a user that is being invited by user or user_id, remove them from
        # emails and let users/user_ids handle it.
        # parsed_emails have to preserve casing due to the invite process also being used to update
        # existing members and we have to let them be found if not lowercased.
        parsed_emails = emails.select do |email|
          # Since we are caching by lowercased emails as a key for the users as they only
          # ever have lowercased emails(except for private_commit_emails), we need to then
          # operate against that cache for lookups like here with a matching lowercase.
          user = users_by_emails[email.downcase]
          !user || (users.exclude?(user) && user_ids.exclude?(user.id))
        end

        if users.present? || users_by_emails.present?
          # helps not have to perform another query per user id to see if the member exists later on when fetching
          existing_members = source.members_and_requesters.with_user(users + users_by_emails.values).index_by(&:user_id)
        end

        [parsed_emails, users, existing_members, users_by_emails]
      end
    end

    def initialize(invitee:, builder: StandardMemberBuilder, **args)
      @invitee = invitee
      @builder = builder
      @args = args
      @access_level = self.class.parsed_access_level(args[:access_level])
    end

    private_class_method :new

    def execute
      find_or_build_member
      commit_member

      member
    end

    private

    delegate :new_record?, to: :member
    attr_reader :invitee, :access_level, :member, :args, :builder

    def assign_member_attributes
      member.attributes = member_attributes
    end

    def commit_member
      return add_commit_error unless can_commit_member?

      assign_member_attributes

      return add_member_role_error if member_role_too_high?

      commit_changes
    end

    def can_commit_member?
      # There is no current user for bulk actions, in which case anything is allowed
      return true if skip_authorization?

      if new_record?
        can_create_new_member?
      else
        can_update_existing_member?
      end
    end

    # overridden in EE:Members::Groups::CreatorService
    def member_role_too_high?
      false
    end

    def can_create_new_member?
      raise NotImplementedError
    end

    def can_update_existing_member?
      raise NotImplementedError
    end

    # Populates the attributes of a member.
    #
    # This logic resides in a separate method so that EE can extend this logic,
    # without having to patch the `add_members` method directly.
    def member_attributes
      {
        created_by: member.created_by || current_user,
        access_level: access_level,
        expires_at: args[:expires_at]
      }
    end

    def commit_changes
      if member.request?
        approve_request
      elsif member.changed?
        # Calling #save triggers callbacks even if there is no change on object.
        # This previously caused an incident due to the hard to predict
        # behaviour caused by the large number of callbacks.
        # See https://gitlab.com/gitlab-com/gl-infra/production/-/issues/6351
        # and https://gitlab.com/gitlab-org/gitlab/-/merge_requests/80920#note_911569038
        # for details.
        member.save
      end
    end

    def approve_request
      ::Members::ApproveAccessRequestService.new(current_user, access_level: access_level)
                                            .execute(
                                              member,
                                              skip_authorization: ldap || skip_authorization?,
                                              skip_log_audit_event: ldap
                                            )
    end

    def current_user
      args[:current_user]
    end

    def skip_authorization?
      !current_user
    end

    def add_commit_error
      msg = if new_record?
              _('not authorized to create member')
            else
              _('not authorized to update member')
            end

      member.errors.add(:base, :unauthorized, message: msg)
    end

    def add_member_role_error
      msg = _("the member access level can't be higher than the current user's one")

      member.errors.add(:base, msg)
    end

    def find_or_build_member
      @member = builder.new(source, invitee, existing_members).execute
    end

    def ldap
      args[:ldap] || false
    end

    def source
      args[:source]
    end

    def existing_members
      args[:existing_members] || {}
    end
  end
end

Members::CreatorService.prepend_mod_with('Members::CreatorService')
