module CiCd
  class GithubIntegrationSetupService
    attr_reader :project

    def initialize(project)
      @project = project
    end

    def execute
      github_integration.save
    end

    private

    def github_integration
      @github_integration ||= project.build_github_service(github_params)
    end

    def github_params
      GithubParams.new(project).configuration_params
    end

    class GithubParams
      def initialize(project)
        @project = project
      end

      def repository_url
        "#{import_uri.scheme}://#{import_uri.host}/#{repo_full_name}"
      end

      def configuration_params
        {
          active: true,
          repository_url: repository_url,
          token: github_access_token
        }
      end

      private

      def github_access_token
        @project.import_data&.credentials&.dig(:user)
      end

      def repo_full_name
        @project.import_source
      end

      def import_uri
        URI.parse(@project.import_url)
      end
    end
  end
end
