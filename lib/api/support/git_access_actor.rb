# frozen_string_literal: true

module API
  module Support
    class GitAccessActor
      extend ::Gitlab::Identifier

      attr_reader :user, :key, :deploy_token

      def initialize(user: nil, key: nil, deploy_token: nil)
        @user = user
        @key = key
        @deploy_token = deploy_token

        @user = key.user if !user && key
      end

      def self.from_params(params)
        if params[:key_id]
          new(key: Key.auth.find_by_id(params[:key_id]))
        elsif params[:user_id]
          new(user: UserFinder.new(params[:user_id]).find_by_id)
        elsif params[:identifier]
          from_identifier(params[:identifier])
        elsif params[:username]
          new(user: UserFinder.new(params[:username]).find_by_username)
        else
          new
        end
      end

      def self.from_identifier(identifier)
        result = identify(identifier)

        case result
        when User
          new(user: result)
        when DeployToken
          new(deploy_token: result)
        else
          new(key: identify_using_deploy_key(identifier))
        end
      end

      # TODO: Rename this method to better reflect that it now includes DeployTokens.
      # We are keeping the name 'key_or_user' for now to avoid a large refactor
      # that would distract from the functional changes in this MR.
      # https://gitlab.com/gitlab-org/gitlab/-/merge_requests/224363
      # A follow-up MR will address the rename across all call sites.
      def key_or_user
        deploy_token || key || user
      end

      def resolved_identity
        return deploy_token if deploy_token

        key.instance_of?(DeployKey) ? key : user
      end

      def username
        user&.username
      end

      def update_last_used_at!
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

API::Support::GitAccessActor.prepend_mod_with('API::Support::GitAccessActor')
