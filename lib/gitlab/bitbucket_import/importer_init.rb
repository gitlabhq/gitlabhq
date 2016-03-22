module Gitlab
  module BitbucketImport
    class ImporterInit
      attr_reader :project, :client

      def initialize(project)
        @project = project
        if import_data_credentials && import_data_credentials['bb_session']
          token = import_data_credentials['bb_session']['bitbucket_access_token']
          token_secret = import_data_credentials['bb_session']['bitbucket_access_token_secret']
          @client = Client.new(token, token_secret)
          @formatter = Gitlab::ImportFormatter.new
        else
          raise Projects::ImportService::Error, "Unable to find project import data credentials for project ID: #{@project.id}"
        end
      end

      private

      def import_data_credentials
        @import_data_credentials ||= project.import_data.credentials if project.import_data
      end
    end
  end
end


