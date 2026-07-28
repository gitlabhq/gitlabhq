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
                  new_file_class(file_class, location)
                end.select(&:matching?)

                if matching.one?
                  verify_include_type_allowed!(matching.first)
                elsif matching.empty?
                  raise Mapper::AmbigiousSpecificationError,
                    "`#{masked_location(location.to_json)}` does not have a valid subkey for #{include_type}. " \
                    "Valid subkeys are: `#{file_subkeys.join('`, `')}`"
                else
                  raise Mapper::AmbigiousSpecificationError,
                    "Each include must use only one of: `#{file_subkeys.join('`, `')}`"
                end
              end
            end

            def new_file_class(file_class, location)
              file_class.new(location, context)
            end

            def verify_include_type_allowed!(file)
              allowed = context.allowed_include_types
              return file if allowed.nil?
              return file if allowed.include?(file.include_type)

              raise Mapper::ForbiddenIncludeTypeError,
                "`#{file.include_type}` includes are not allowed in this context. " \
                "Allowed include types are: `#{allowed.join('`, `')}`"
            end

            def masked_location(location)
              context.mask_variables_from(location)
            end

            def file_subkeys
              file_classes.map { |f| f.name.demodulize.downcase }.freeze
            end
            strong_memoize_attr :file_subkeys

            def include_type
              'include'
            end

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
