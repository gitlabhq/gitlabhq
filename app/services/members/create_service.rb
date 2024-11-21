# frozen_string_literal: true

module Members
  class CreateService < Members::BaseService
    BlankInvitesError = Class.new(StandardError)
    TooManyInvitesError = Class.new(StandardError)
    MembershipLockedError = Class.new(StandardError)
    SeatLimitExceededError = Class.new(StandardError)

    DEFAULT_INVITE_LIMIT = 100

    attr_reader :membership_locked, :http_status

    def initialize(*args)
      super

      @errors = []
      @http_status = nil
      @invites = invites_from_params
      @source = params[:source]
    end

    def execute
      validate_source_type!

      if adding_at_least_one_owner && cannot_assign_owner_responsibilities_to_member_in_project?
        raise Gitlab::Access::AccessDeniedError
      end

      validate_invite_source!
      validate_invitable!

      add_members
      after_add_hooks

      publish_event!

      result
    rescue BlankInvitesError, TooManyInvitesError, MembershipLockedError, SeatLimitExceededError => e
      Gitlab::ErrorTracking.log_exception(e, class: self.class.to_s, user_id: current_user&.id)

      error(e.message, pass_back: { reason: e.class.name.demodulize.underscore.to_sym })
    end

    def single_member
      members&.last
    end

    private

    attr_reader :source, :errors, :invites, :member_created_namespace_id, :members

    def adding_at_least_one_owner
      params[:access_level] == Gitlab::Access::OWNER
    end

    def cannot_assign_owner_responsibilities_to_member_in_project?
      source.is_a?(Project) && !current_user&.can?(:manage_owners, source)
    end

    def invites_from_params
      # String, Nil, Array, Integer
      users = param_to_array(params[:user_id] || params[:username])
      if params.key?(:username)
        User.by_username(users).pluck_primary_key
      else
        users.to_a
      end
    end

    def param_to_array(param)
      return param if param.is_a?(Array)

      param.to_s.split(',').uniq
    end

    def validate_source_type!
      raise "Unknown source type: #{source.class}!" unless source.is_a?(Group) || source.is_a?(Project)
    end

    def validate_invite_source!
      raise ArgumentError, s_('AddMember|No invite source provided.') unless invite_source.present?
    end

    def validate_invitable!
      raise BlankInvitesError, blank_invites_message if invites.blank?

      return unless user_limit && invites.size > user_limit

      message = format(s_("AddMember|Too many users specified (limit is %{user_limit})"), user_limit: user_limit)
      raise TooManyInvitesError, message
    end

    def blank_invites_message
      s_('AddMember|No users specified.')
    end

    def add_members
      @members = creator_service.add_members(
        source, invites, params[:access_level], **create_params
      )

      members.each { |member| process_result(member) }
    end

    def creator_service
      "Members::#{source.class.to_s.pluralize}::CreatorService".constantize
    end

    def create_params
      {
        expires_at: params[:expires_at],
        current_user: current_user
      }
    end

    def process_result(member)
      @http_status = :unauthorized if member.errors.added? :base, :unauthorized
      existing_errors = member.errors.full_messages

      # calling invalid? clears any errors that were added outside of the
      # rails validation process
      if member.invalid? || existing_errors.present?
        add_error_for_member(member, existing_errors)
      else
        after_execute(member: member)
        @member_created_namespace_id ||= member.namespace_id
      end
    end

    # overridden
    def add_error_for_member(member, existing_errors)
      prefix = "#{member.user.username}: " if member.user.present?

      errors << "#{prefix}#{all_member_errors(member, existing_errors).to_sentence}"
    end

    def all_member_errors(member, existing_errors)
      existing_errors.concat(member.errors.full_messages).uniq
    end

    def after_add_hooks
      # overridden in subclasses/ee
    end

    def after_execute(member:)
      super

      track_invite_source(member)
    end

    def track_invite_source(member)
      Gitlab::Tracking.event(
        self.class.name,
        'create_member',
        label: invite_source,
        property: tracking_property(member),
        user: current_user
      )
    end

    def invite_source
      params[:invite_source]
    end

    def tracking_property(member)
      # ideally invites go down the invite service class instead, but there is nothing that limits an invite
      # from being used in this class and if you send emails as a comma separated list to the api/members
      # endpoint, it will support invites
      member.invite? ? 'net_new_user' : 'existing_user'
    end

    def user_limit
      limit = params.fetch(:limit, DEFAULT_INVITE_LIMIT)

      limit && limit < 0 ? nil : limit
    end

    def at_least_one_member_created?
      member_created_namespace_id.present?
    end

    def result(pass_back = {})
      if errors.any?
        error(formatted_errors, http_status, pass_back: pass_back)
      else
        success(pass_back)
      end
    end

    def formatted_errors
      errors.to_sentence
    end

    def publish_event!
      return unless at_least_one_member_created?

      Gitlab::EventStore.publish(
        Members::MembersAddedEvent.new(data: {
          source_id: source.id,
          source_type: source.class.name,
          invited_user_ids: invites
        })
      )
    end
  end
end

Members::CreateService.prepend_mod_with('Members::CreateService')
