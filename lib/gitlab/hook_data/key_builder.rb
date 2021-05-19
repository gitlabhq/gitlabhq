# frozen_string_literal: true

module Gitlab
  module HookData
    class KeyBuilder < BaseBuilder
      alias_method :key, :object

      # Sample data
      # {
      #   event_name: "key_create",
      #   created_at: "2021-04-19T06:13:24Z",
      #   updated_at: "2021-04-19T06:13:24Z",
      #   key: "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAAAgQClDn/5BaESHlSb3NxQtiUc0BXgK6lsqdAUIdS3lwZ2gbACDhtoLYnc+qhZ4b8gWzE+2A8RmkvLe98T7noRoW4DAYs67NSqMs/kXd2ESPNV8qqv0u7tCxPz+c7DaYp2oC/avlxVQ2AeULZLCEwalYZ7irde0EZMeTwNIRu5s88gOw== dummy@gitlab.com",
      #   id: 1,
      #   username: "johndoe"
      # }

      def build(event)
        [
          event_data(event),
          timestamps_data,
          key_data,
          user_data
        ].reduce(:merge)
      end

      private

      def key_data
        {
          key: key.key,
          id: key.id
        }
      end

      def user_data
        user = key.user
        return {} unless user

        {
          username: user.username
        }
      end
    end
  end
end
