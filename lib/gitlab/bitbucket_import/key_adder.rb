module Gitlab
  module BitbucketImport
    class KeyAdder
      attr_reader :repo, :current_user, :client

      def initialize(repo, current_user)
        @repo, @current_user = repo, current_user
        @client = Client.new(current_user.bitbucket_access_token, current_user.bitbucket_access_token_secret)
      end

      def execute
        project_identifier = "#{repo["owner"]}/#{repo["slug"]}"
        return true if client.deploy_key(project_identifier)

        # TODO: Point to actual public key.
        client.add_deploy_key(project_identifier, File.read("/Users/douwemaan/.ssh/id_rsa.pub"))

        true
      end
    end
  end
end
