# frozen_string_literal: true

module Gitlab
  module Ci
    module Pipeline
      module Chain
        module Config
          class Process < Chain::Base
            include Chain::Helpers

            def perform!
              raise ArgumentError, 'missing config content' unless @command.config_content

              @command.config_processor = ::Gitlab::Ci::YamlProcessor.new(
                @command.config_content, {
                  project: project,
                  sha: @pipeline.sha,
                  user: current_user
                }
              )
            rescue Gitlab::Ci::YamlProcessor::ValidationError => ex
              error(ex.message, config_error: true)
            rescue => ex
              Gitlab::Sentry.track_acceptable_exception(ex, extra: {
                project_id: project.id,
                sha: @pipeline.sha
              })

              error("Undefined error (#{Labkit::Correlation::CorrelationId.current_id})",
                config_error: true)
            end

            def break?
              @pipeline.errors.any? || @pipeline.persisted?
            end
          end
        end
      end
    end
  end
end
