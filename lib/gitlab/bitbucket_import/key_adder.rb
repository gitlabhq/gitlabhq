module Gitlab
  module BitbucketImport
    class KeyAdder
      attr_reader :repo, :current_user, :client

      def initialize(repo, current_user)
        @repo, @current_user = repo, current_user
        @client = Client.new(current_user.bitbucket_access_token, current_user.bitbucket_access_token_secret)
      end

      def execute
        return false unless BitbucketImport.public_key.present?
        
        project_identifier = "#{repo["owner"]}/#{repo["slug"]}"
        client.add_deploy_key(project_identifier, BitbucketImport.public_key)

        true
      rescue
        false
      end
    end
  end
end
