# frozen_string_literal: true

module Gitlab
  module Ci
    class Config
      module External
        class Mapper
          # Fetches file contents and verifies them
          class Verifier < Base
            private

            def process_without_instrumentation(files)
              files.select do |file|
                verify_max_includes!
                verify_execution_time!

                file.validate!

                context.expandset.add(file)
              end
            end

            def verify_max_includes!
              return if context.expandset.count < context.max_includes

              raise Mapper::TooManyIncludesError, "Maximum of #{context.max_includes} nested includes are allowed!"
            end

            def verify_execution_time!
              context.check_execution_time!
            end
          end
        end
      end
    end
  end
end
