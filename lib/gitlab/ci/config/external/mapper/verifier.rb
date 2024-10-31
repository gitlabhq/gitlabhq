# frozen_string_literal: true

require 'objspace'

module Gitlab
  module Ci
    class Config
      module External
        class Mapper
          # Fetches file contents and verifies them
          class Verifier < Base
            private

            def process_without_instrumentation(files)
              files.each do |file|
                # When running a pipeline, some Ci::ProjectConfig sources prepend the config content with an
                # "internal" `include`. We use this condition to exclude that `include` from the included file set.
                context.expandset << file unless context.internal_include?
                verify_max_includes!

                verify_execution_time!

                file.validate_location!
                file.preload_context if file.valid?
              end

              # We do not combine the loops because we need to preload the context of all files via `BatchLoader`.
              files.each do |file| # rubocop:disable Style/CombinableLoops
                verify_execution_time!

                file.validate_context! if file.valid?
                file.preload_content if file.valid?
              end

              # We do not combine the loops because we need to preload the content of all files via `BatchLoader`
              # or `Concurrent::Promise`.
              files.each do |file| # rubocop:disable Style/CombinableLoops
                verify_execution_time!

                file.validate_content! if file.valid?
                file.load_and_validate_expanded_hash! if file.valid?

                next unless file.valid?

                # We are checking the file.content.to_s because that is returning the actual content of the file,
                # whereas file.content would return the BatchLoader.
                context.total_file_size_in_bytes += ObjectSpace.memsize_of(file.content.to_s)
                verify_max_total_pipeline_size!
              end
            end

            def verify_max_includes!
              return if context.expandset.count <= context.max_includes

              raise Mapper::TooManyIncludesError, "Maximum of #{context.max_includes} nested includes are allowed!"
            end

            def verify_execution_time!
              context.check_execution_time!
            end

            def verify_max_total_pipeline_size!
              return if context.total_file_size_in_bytes <= context.max_total_yaml_size_bytes

              raise Mapper::TooMuchDataInPipelineTreeError, "Total size of combined CI/CD configuration is too big"
            end
          end
        end
      end
    end
  end
end
