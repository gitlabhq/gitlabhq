# frozen_string_literal: true

module API
  module Support
    class GitAccessActor
      extend ::Gitlab::Identifier

      attr_reader :user, :key

      def initialize(user: nil, key: nil)
        @user = user
        @key = key

        @user = key.user if !user && key
      end

      def self.from_params(params)
        if params[:key_id]
          new(key: Key.find_by_id(params[:key_id]))
        elsif params[:user_id]
          new(user: UserFinder.new(params[:user_id]).find_by_id)
        elsif params[:username]
          new(user: UserFinder.new(params[:username]).find_by_username)
        elsif params[:identifier]
          new(user: identify(params[:identifier]))
        else
          new
        end
      end

      def key_or_user
        key || user
      end

      def username
        user&.username
      end

      def update_last_used_at!
        return if Feature.enabled?(:disable_ssh_key_used_tracking)

        key&.update_last_used_at
      end

      def key_details
        return {} unless key

        {
          gl_key_type: key.model_name.singular,
          gl_key_id: key.id
        }
      end
    end
  end
end
