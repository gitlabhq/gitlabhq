# frozen_string_literal: true

module Gitlab
  module Ci
    class Config
      module External
        class Mapper
          # Matches the first file type that matches the given location
          class Matcher < Base
            FILE_CLASSES = [
              External::File::Local,
              External::File::Project,
              External::File::Remote,
              External::File::Template,
              External::File::Artifact
            ].freeze

            FILE_SUBKEYS = FILE_CLASSES.map { |f| f.name.demodulize.downcase }.freeze

            private

            def process_without_instrumentation(locations)
              locations.map do |location|
                matching = FILE_CLASSES.map do |file_class|
                  file_class.new(location, context)
                end.select(&:matching?)

                if matching.one?
                  matching.first
                elsif matching.empty?
                  raise Mapper::AmbigiousSpecificationError,
                        "`#{masked_location(location.to_json)}` does not have a valid subkey for include. " \
                        "Valid subkeys are: `#{FILE_SUBKEYS.join('`, `')}`"
                else
                  raise Mapper::AmbigiousSpecificationError,
                        "Each include must use only one of: `#{FILE_SUBKEYS.join('`, `')}`"
                end
              end
            end

            def masked_location(location)
              context.mask_variables_from(location)
            end
          end
        end
      end
    end
  end
end
