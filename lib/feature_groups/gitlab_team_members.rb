# frozen_string_literal: true

module FeatureGroups
  class GitlabTeamMembers
    GITLAB_COM_GROUP_ID = 6543

    class << self
      def enabled?(thing)
        return false unless Gitlab.com?

        team_member?(thing)
      end

      private

      def team_member?(thing)
        thing.is_a?(::User) && gitlab_com_member_ids.include?(thing.id)
      end

      def gitlab_com
        @gitlab_com ||= ::Group.find(GITLAB_COM_GROUP_ID)
      end

      def gitlab_com_member_ids
        Rails.cache.fetch("gitlab_team_members", expires_in: 1.hour) do
          gitlab_com.members.pluck_user_ids.to_set
        end
      end
    end
  end
end
