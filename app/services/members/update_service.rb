# frozen_string_literal: true

module Members
  class UpdateService < Members::BaseService
    def initialize(*args)
      super

      @source = params[:source]
    end

    # @param members [Member, Array<Member>]
    # returns the updated member(s)
    def execute(members, permission: :update)
      validate_source_type!

      members = Array.wrap(members)

      old_access_level_expiry_map = members.to_h do |member|
        [member.id, { human_access: member.human_access_labeled, expires_at: member.expires_at }]
      end

      updated_members = update_members(members, permission)
      Member.transaction do
        updated_members.each { |member| post_update(member, permission, old_access_level_expiry_map) }
      end

      prepare_response(members)

    rescue ActiveRecord::RecordInvalid
      prepare_response(members)
    end

    private

    attr_reader :source

    def validate_source_type!
      raise "Unknown source type: #{source.class}!" unless source.is_a?(Group) || source.is_a?(Project)
    end

    def update_members(members, permission)
      # `filter_map` avoids the `post_update` call for the member that resulted in no change
      Member.transaction do
        members.filter_map { |member| update_member(member, permission) }
      end
    end

    def update_member(member, permission)
      raise Gitlab::Access::AccessDeniedError unless has_update_permissions?(member, permission)

      member.attributes = params
      return unless member.changed?

      member.expiry_notified_at = nil if member.expires_at_changed?

      member.tap(&:save!)
    end

    def post_update(member, permission, old_access_level_expiry_map)
      old_access_level = old_access_level_expiry_map[member.id][:human_access]
      old_expiry = old_access_level_expiry_map[member.id][:expires_at]

      after_execute(action: permission, old_access_level: old_access_level, old_expiry: old_expiry, member: member)
      enqueue_delete_todos(member) if downgrading_to_guest? # Deletes only confidential issues todos for guests
    end

    def prepare_response(members)
      errored_members = members.select { |member| member.errors.any? }
      if errored_members.present?
        error_message = errored_members.flat_map { |member| member.errors.full_messages }.uniq.to_sentence
        return error(error_message, pass_back: { members: errored_members })
      end

      success(members: members)
    end

    def has_update_permissions?(member, permission)
      can?(current_user, action_member_permission(permission, member), member) &&
        !prevent_upgrade_to_owner?(member) &&
        !prevent_downgrade_from_owner?(member)
    end

    def downgrading_to_guest?
      params[:access_level] == Gitlab::Access::GUEST
    end

    def upgrading_to_owner?
      params[:access_level] == Gitlab::Access::OWNER
    end

    def downgrading_from_owner?(member)
      member.owner?
    end

    def prevent_upgrade_to_owner?(member)
      upgrading_to_owner? && cannot_assign_owner_responsibilities_to_member_in_project?(member)
    end

    def prevent_downgrade_from_owner?(member)
      downgrading_from_owner?(member) && cannot_revoke_owner_responsibilities_from_member_in_project?(member)
    end
  end
end

Members::UpdateService.prepend_mod_with('Members::UpdateService')
