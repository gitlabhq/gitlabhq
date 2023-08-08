# frozen_string_literal: true

module Gitlab
  module Ci
    class Config
      module External
        class Mapper
          # Matches the first file type that matches the given location
          class Matcher < Base
            include Gitlab::Utils::StrongMemoize

            private

            def process_without_instrumentation(locations)
              locations.map do |location|
                matching = file_classes.map do |file_class|
                  file_class.new(location, context)
                end.select(&:matching?)

                if matching.one?
                  matching.first
                elsif matching.empty?
                  raise Mapper::AmbigiousSpecificationError,
                    "`#{masked_location(location.to_json)}` does not have a valid subkey for include. " \
                    "Valid subkeys are: `#{file_subkeys.join('`, `')}`"
                else
                  raise Mapper::AmbigiousSpecificationError,
                    "Each include must use only one of: `#{file_subkeys.join('`, `')}`"
                end
              end
            end

            def masked_location(location)
              context.mask_variables_from(location)
            end

            def file_subkeys
              file_classes.map { |f| f.name.demodulize.downcase }.freeze
            end
            strong_memoize_attr :file_subkeys

            def file_classes
              [
                External::File::Local,
                External::File::Project,
                External::File::Remote,
                External::File::Template,
                External::File::Artifact,
                External::File::Component
              ]
            end
            strong_memoize_attr :file_classes
          end
        end
      end
    end
  end
end
