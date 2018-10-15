# frozen_string_literal: true

module Gitlab
  module Ci
    module External
      class Mapper
        IncludeError = Class.new(StandardError)

        def initialize(values, project, sha)
          @values = values
          @project = project
          @sha = sha
        end

        def process
          included = @values[:include]

          return [] if included.nil?

          if string_or_array_of_strings?(included)
            included = Array(included).map do |path|
              {
                path: path,
                ignore_if_missing: false
              }
            end
          elsif included.is_a?(Hash)
            included = [included]
          end

          included.map {|i| build_external_file(i) }
        end

        private

        def build_external_file(included)
          location = included.fetch(:path)
          if ::Gitlab::UrlSanitizer.valid?(location)
            if included.fetch(:ignore_if_missing)
              raise IncludeError, 'ignore_if_missing must be false or not included for remote files'
            end

            Gitlab::Ci::External::File::Remote.new(location)
          else
            Gitlab::Ci::External::File::Local.new(
              location,
              project: @project,
              sha: @sha,
              ignore_if_missing: included.fetch(:ignore_if_missing, false)
            )
          end
        end

        def string_or_array_of_strings?(value)
          value.is_a?(String) || (value.is_a?(Array) && value[0].is_a?(String))
        end
      end
    end
  end
end
