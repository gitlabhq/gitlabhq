# frozen_string_literal: true

module QA
  module Resource
    #
    # Included in Resource::Project and Resource::Group to allow changes to
    # project/group membership
    #
    module Members
      def add_member(user, access_level = AccessLevel::DEVELOPER)
        Support::Retrier.retry_until do
          QA::Runtime::Logger.debug(%Q[Adding user #{user.username} to #{full_path} #{self.class.name}])

          response = post Runtime::API::Request.new(api_client, api_members_path).url, { user_id: user.id, access_level: access_level }
          response.code == QA::Support::Api::HTTP_STATUS_CREATED
        end
      end

      def remove_member(user)
        QA::Runtime::Logger.debug(%Q[Removing user #{user.username} from #{full_path} #{self.class.name}])

        delete Runtime::API::Request.new(api_client, "#{api_members_path}/#{user.id}").url
      end

      def list_members
        JSON.parse(get(Runtime::API::Request.new(api_client, api_members_path).url).body)
      end

      def invite_group(group, access_level = AccessLevel::GUEST)
        Support::Retrier.retry_until do
          QA::Runtime::Logger.debug(%Q[Sharing #{self.class.name} with #{group.name}])

          response = post Runtime::API::Request.new(api_client, api_share_path).url, { group_id: group.id, group_access: access_level }
          response.code == QA::Support::Api::HTTP_STATUS_CREATED
        end
      end

      def api_members_path
        "#{api_get_path}/members"
      end

      def api_share_path
        "#{api_get_path}/share"
      end

      class AccessLevel
        NO_ACCESS      = 0
        MINIMAL_ACCESS = 5
        GUEST          = 10
        REPORTER       = 20
        DEVELOPER      = 30
        MAINTAINER     = 40
        OWNER          = 50
      end
    end
  end
end
