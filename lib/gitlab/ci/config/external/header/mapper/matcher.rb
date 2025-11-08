# frozen_string_literal: true

module Gitlab
  module Ci
    class Config
      module External
        module Header
          class Mapper
            ##
            # Header-specific matcher that reuses the core matching logic
            # but only matches header-compatible file types
            class Matcher < ::Gitlab::Ci::Config::External::Mapper::Matcher
              private

              def new_file_class(file_class, location)
                file_class.new(location, context).inputs_only!
              end

              # Override to provide header-compatible file classes
              def file_classes
                [
                  External::File::Local,
                  External::File::Remote,
                  External::File::Project
                ]
              end

              def include_type
                'header include'
              end
            end
          end
        end
      end
    end
  end
end
