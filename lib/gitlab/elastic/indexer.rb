module Gitlab
  module Elastic
    class Indexer
      include Gitlab::CurrentSettings

      Error = Class.new(StandardError)

      def initialize
        connection_info = {
          host: current_application_settings.elasticsearch_host,
          port: current_application_settings.elasticsearch_port
        }.to_json

        # We accept any form of settings, including string and array
        # This is why JSON is needed
        @vars = {
          'ELASTIC_CONNECTION_INFO' => connection_info,
          'RAILS_ENV'               => Rails.env
        }
      end

      def run(project_id, repo_path, from_sha = nil, to_sha = nil)
        to_sha = nil if to_sha == Gitlab::Git::BLANK_SHA

        vars = @vars.merge({ 'FROM_SHA' => from_sha, 'TO_SHA' => to_sha })

        path_to_indexer = File.join(Rails.root, 'bin/elastic_repo_indexer')

        command = [path_to_indexer, project_id.to_s, repo_path]

        output, status = Gitlab::Popen.popen(command, nil, vars)

        raise Error, output unless status.zero?

        true
      end
    end
  end
end
