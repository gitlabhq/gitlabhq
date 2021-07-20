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
        raise NotImplementedError
      end

      def add_users(source, users, access_level, current_user: nil, expires_at: nil)
        return [] unless users.present?

        emails, users, existing_members = parse_users_list(source, users)

        Member.transaction do
          (emails + users).map! do |user|
            new(source,
                user,
                access_level,
                existing_members: existing_members,
                current_user: current_user,
                expires_at: expires_at)
              .execute
          end
        end
      end

      private

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

        if user_ids.present?
          users.concat(User.id_in(user_ids))
          # the below will automatically discard invalid user_ids
          existing_members = source.members_and_requesters.where(user_id: user_ids).index_by(&:user_id) # rubocop:todo CodeReuse/ActiveRecord
        end

        [emails, users, existing_members]
      end
    end

    def initialize(source, user, access_level, **args)
      @source = source
      @user = user
      @access_level = self.class.parsed_access_level(access_level)
      @args = args
    end

    def execute
      find_or_build_member
      update_member

      member
    end

    private

    attr_reader :source, :user, :access_level, :member, :args

    def update_member
      return unless can_update_member?

      member.attributes = member_attributes

      if member.request?
        approve_request
      else
        member.save
      end
    end

    def can_update_member?
      # There is no current user for bulk actions, in which case anything is allowed
      !current_user # inheriting classes will add more logic
    end

    # Populates the attributes of a member.
    #
    # This logic resides in a separate method so that EE can extend this logic,
    # without having to patch the `add_user` method directly.
    def member_attributes
      {
        created_by: member.created_by || current_user,
        access_level: access_level,
        expires_at: args[:expires_at]
      }
    end

    def approve_request
      ::Members::ApproveAccessRequestService.new(current_user,
                                                 access_level: access_level)
                                            .execute(
                                              member,
                                              skip_authorization: ldap,
                                              skip_log_audit_event: ldap
                                            )
    end

    def current_user
      args[:current_user]
    end

    def find_or_build_member
      @user = parse_user_param

      @member = if user.is_a?(User)
                  find_or_initialize_member_by_user
                else
                  source.members.build(invite_email: user)
                end
    end

    # This method is used to find users that have been entered into the "Add members" field.
    # These can be the User objects directly, their IDs, their emails, or new emails to be invited.
    def parse_user_param
      case user
      when User
        user
      when Integer
        # might not return anything - this needs enhancement
        User.find_by(id: user) # rubocop:todo CodeReuse/ActiveRecord
      else
        # must be an email or at least we'll consider it one
        User.find_by_any_email(user) || user
      end
    end

    def find_or_initialize_member_by_user
      if existing_members
        # TODO: https://gitlab.com/gitlab-org/gitlab/-/issues/334062
        # i'm not so sure this is needed as the parse_users_list looks at members_and_requesters...
        # so it is like we could just do a find or initialize by here and be fine
        existing_members[user.id] || source.members.build(user_id: user.id)
      else
        source.members_and_requesters.find_or_initialize_by(user_id: user.id) # rubocop:todo CodeReuse/ActiveRecord
      end
    end

    def existing_members
      args[:existing_members]
    end

    def ldap
      args[:ldap] || false
    end
  end
end

Members::CreatorService.prepend_mod_with('Members::CreatorService')
