# frozen_string_literal: true

module Gitlab
  module HookData
    class UserBuilder < BaseBuilder
      alias_method :user, :object

      # Sample data
      # {
      # :created_at=>"2021-04-02T10:00:26Z",
      # :updated_at=>"2021-04-02T10:00:26Z",
      # :event_name=>"user_create",
      # :name=>"John Doe",
      # :email=>"john@example.com",
      # :user_id=>1,
      # :username=>"johndoe"
      # }

      def build(event)
        [
          timestamps_data,
          event_data(event),
          user_data,
          event_specific_user_data(event)
        ].reduce(:merge)
      end

      private

      def user_data
        {
          name: user.name,
          email: user.email,
          user_id: user.id,
          username: user.username
        }
      end

      def event_specific_user_data(event)
        case event
        when :rename
          { old_username: user.username_before_last_save }
        when :failed_login
          { state: user.state }
        else
          {}
        end
      end
    end
  end
end

Gitlab::HookData::UserBuilder.prepend_mod_with('Gitlab::HookData::UserBuilder')
