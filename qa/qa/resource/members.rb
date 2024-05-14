# frozen_string_literal: true

module QA
  module Resource
    # Included in Resource::Project and Resource::Group to allow changes to
    # project/group membership
    module Members
      # Add single user to group or project
      #
      # @param [Resource::User] user
      # @param [Integer] access_level
      def add_member(user, access_level = AccessLevel::DEVELOPER)
        Support::Retrier.retry_until do
          QA::Runtime::Logger.info(%(Adding user #{user.username} to #{full_path} #{self.class.name}))
          response = post Runtime::API::Request.new(api_client, api_members_path).url,
            { user_id: user.id, access_level: access_level }
          break true if response.code == QA::Support::API::HTTP_STATUS_CREATED
          break true if response.body.include?('Member already exists')
        end
      end

      # Add multiple users to group or project with default access level
      #
      # @param [Array<Resource::User>] users
      def add_members(*users)
        users.each do |user|
          add_member(user)
        end
      end

      # Update the access level for single user in a group or project
      #
      # @param [Resource::User] user
      # @param [Integer] access_level (default Developer)
      def update_member(user, access_level: AccessLevel::DEVELOPER)
        Support::Retrier.retry_until do
          QA::Runtime::Logger.info(%(Updating user #{user.username} in #{full_path} #{self.class.name}))
          response = put Runtime::API::Request.new(api_client, "#{api_members_path}/#{user.id}").url,
            { access_level: access_level }
          next true if success?(response.code)
        end
      end

      # Update the access level for multiple users in a group or project
      #
      # @param [Array<Resource::User>] users
      # @param [Integer] access_level (default Developer)
      def update_members(*users, access_level: AccessLevel::DEVELOPER)
        users.each do |user|
          update_member(user, access_level: access_level)
        end
      end

      def remove_member(user)
        QA::Runtime::Logger.info(%(Removing user #{user.username} from #{full_path} #{self.class.name}))

        delete Runtime::API::Request.new(api_client, "#{api_members_path}/#{user.id}").url
      end

      def list_members
        parse_body(api_get_from(api_members_path))
      end

      def list_all_members
        parse_body(api_get_from("#{api_members_path}/all"))
      end

      def find_member(username)
        list_members.find { |member| member[:username] == username }
      end

      def invite_group(group, access_level = AccessLevel::GUEST)
        Support::Retrier.retry_until do
          QA::Runtime::Logger.info(%(Sharing #{self.class.name} with #{group.name}))

          response = post Runtime::API::Request.new(api_client, api_share_path).url,
            { group_id: group.id, group_access: access_level }
          response.code == QA::Support::API::HTTP_STATUS_CREATED
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
