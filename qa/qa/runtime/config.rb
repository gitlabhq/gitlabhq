require 'pathname'
require 'yaml'

module QA
  module Runtime
    class Config
      GITLAB_YML_FILENAME = '../config/gitlab.yml'.freeze

      attr_accessor :config

      def initialize
        load_gitlab_config
      end

      def backup_path
        path = config['production']['backup']['path']

        return path if Pathname.new(path).absolute?

        File.join('..', path)
      end

      private

      def load_gitlab_config
        @config = YAML.load_file(GITLAB_YML_FILENAME)
      end
    end
  end
end
