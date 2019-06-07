# frozen_string_literal: true

module Gitlab
  module Ci
    class Config
      module External
        class Mapper
          include Gitlab::Utils::StrongMemoize

          MAX_INCLUDES = 50

          FILE_CLASSES = [
            External::File::Remote,
            External::File::Template,
            External::File::Local,
            External::File::Project
          ].freeze

          Error = Class.new(StandardError)
          AmbigiousSpecificationError = Class.new(Error)
          DuplicateIncludesError = Class.new(Error)
          TooManyIncludesError = Class.new(Error)

          def initialize(values, project:, sha:, user:, expandset:)
            raise Error, 'Expanded needs to be `Set`' unless expandset.is_a?(Set)

            @locations = Array.wrap(values.fetch(:include, []))
            @project = project
            @sha = sha
            @user = user
            @expandset = expandset
          end

          def process
            return [] if locations.empty?

            locations
              .compact
              .map(&method(:normalize_location))
              .each(&method(:verify_duplicates!))
              .map(&method(:select_first_matching))
          end

          private

          attr_reader :locations, :project, :sha, :user, :expandset

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

          def verify_duplicates!(location)
            if expandset.count >= MAX_INCLUDES
              raise TooManyIncludesError, "Maximum of #{MAX_INCLUDES} nested includes are allowed!"
            end

            # We scope location to context, as this allows us to properly support
            # relative incldues, and similarly looking relative in another project
            # does not trigger duplicate error
            scoped_location = location.merge(
              context_project: project,
              context_sha: sha)

            unless expandset.add?(scoped_location)
              raise DuplicateIncludesError, "Include `#{location.to_json}` was already included!"
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
              External::File::Base::Context.new(project, sha, user, expandset)
            end
          end
        end
      end
    end
  end
end
