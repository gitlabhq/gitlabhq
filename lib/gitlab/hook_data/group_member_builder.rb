# frozen_string_literal: true

module Gitlab
  module HookData
    class GroupMemberBuilder < BaseBuilder
      alias_method :group_member, :object

      # Sample data

      # {
      #   :event_name=>"user_add_to_group",
      #   :group_name=>"GitLab group",
      #   :group_path=>"gitlab",
      #   :group_id=>1,
      #   :user_username=>"robert",
      #   :user_name=>"Robert Mills",
      #   :user_email=>"robert@example.com",
      #   :user_id=>14,
      #   :group_access=>"Guest",
      #   :created_at=>"2020-11-04T10:12:10Z",
      #   :updated_at=>"2020-11-04T10:12:10Z",
      #   :expires_at=>"2020-12-04T10:12:10Z"
      # }

      def build(event)
        [
          timestamps_data,
          group_member_data,
          event_data(event)
        ].reduce(:merge)
      end

      private

      def group_member_data
        {
          group_name: group_member.group.name,
          group_path: group_member.group.path,
          group_id: group_member.group.id,
          user_username: group_member.user.username,
          user_name: group_member.user.name,
          user_email: group_member.user.webhook_email,
          user_id: group_member.user.id,
          group_access: group_member.human_access,
          expires_at: group_member.expires_at&.xmlschema
        }
      end

      def event_data(event)
        event_name =  case event
                      when :create
                        'user_add_to_group'
                      when :destroy
                        'user_remove_from_group'
                      when :update
                        'user_update_for_group'
                      when :request
                        'user_access_request_to_group'
                      when :revoke
                        'user_access_request_revoked_for_group'
                      end

        { event_name: event_name }
      end
    end
  end
end

Gitlab::HookData::GroupMemberBuilder.prepend_mod_with('Gitlab::HookData::GroupMemberBuilder')
