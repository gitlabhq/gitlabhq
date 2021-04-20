# frozen_string_literal: true

module Packages
  module Composer
    class ComposerJsonService
      InvalidJson = Class.new(StandardError)

      def initialize(project, target)
        @project = project
        @target = target
      end

      def execute
        composer_json
      end

      private

      def composer_json
        composer_file = @project.repository.blob_at(@target, 'composer.json')

        composer_file_not_found! unless composer_file

        Gitlab::Json.parse(composer_file.data)
      rescue JSON::ParserError
        raise InvalidJson, 'Could not parse composer.json file. Invalid JSON.'
      end

      def composer_file_not_found!
        raise InvalidJson, 'The file composer.json was not found.'
      end
    end
  end
end
