# frozen_string_literal: true

module Gitlab
  module Ci
    class Config
      module External
        class Mapper
          include Gitlab::Utils::StrongMemoize

          FILE_CLASSES = [
            External::File::Remote,
            External::File::Template,
            External::File::Local
          ].freeze

          AmbigiousSpecificationError = Class.new(StandardError)

          def initialize(values, project:, sha:)
            @locations = Array.wrap(values.fetch(:include, []))
            @project = project
            @sha = sha
          end

          def process
            locations
              .compact
              .map(&method(:normalize_location))
              .map(&method(:select_first_matching))
          end

          private

          attr_reader :locations, :project, :sha, :user

          # convert location if String to canonical form
          def normalize_location(location)
            if location.is_a?(String)
              normalize_location_string(location)
            else
              location.deep_symbolize_keys
            end
          end

          def normalize_location_string(location)
            if ::Gitlab::UrlSanitizer.valid?(location)
              { remote: location }
            else
              { local: location }
            end
          end

          def select_first_matching(location)
            matching = FILE_CLASSES.map do |file_class|
              file_class.new(location, context)
            end.select(&:matching?)

            raise AmbigiousSpecificationError, "Include `#{location.to_json}` needs to match exactly one accessor!" unless matching.one?

            matching.first
          end

          def context
            strong_memoize(:context) do
              External::File::Base::Context.new(project, sha)
            end
          end
        end
      end
    end
  end
end
