# frozen_string_literal: true

module Gitlab
  module Bullet
    class Exclusions
      def initialize(config_file = Gitlab.root.join('config/bullet.yml'))
        @config_file = config_file
      end

      def execute
        exclusions.map { |v| v['exclude'] }
      end

      def validate_paths!
        exclusions.each do |properties|
          next unless properties['path_with_method']

          file = properties['exclude'].first

          raise "Bullet: File used by #{config_file} doesn't exist, validate the #{file} exclusion!" unless File.exist?(file)
        end
      end

      private

      attr_reader :config_file

      def exclusions
        @exclusions ||= if File.exist?(config_file)
                          YAML.load_file(config_file)['exclusions']&.values || []
                        else
                          []
                        end
      end
    end
  end
end
