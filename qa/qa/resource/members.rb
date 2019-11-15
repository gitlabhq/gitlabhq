# frozen_string_literal: true

module QA
  module Resource
    #
    # Included in Resource::Project and Resource::Group to allow changes to
    # project/group membership
    #
    module Members
      def add_member(user, access_level = AccessLevel::DEVELOPER)
        post Runtime::API::Request.new(api_client, api_members_path).url, { user_id: user.id, access_level: access_level }
      end

      def list_members
        JSON.parse(get(Runtime::API::Request.new(api_client, api_members_path).url).body)
      end

      def api_members_path
        "#{api_get_path}/members"
      end

      class AccessLevel
        NO_ACCESS  = 0
        GUEST      = 10
        REPORTER   = 20
        DEVELOPER  = 30
        MAINTAINER = 40
        OWNER      = 50
      end
    end
  end
end
