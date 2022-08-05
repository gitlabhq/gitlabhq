# frozen_string_literal: true

module Gitlab
  module Ci
    module Artifacts
      module Logger
        def log_artifacts_filesize(artifact_file)
          return if artifact_file.nil?

          unless artifact_file.is_a?(::Ci::Artifactable)
            raise ArgumentError, "unknown artifact file class `#{artifact_file.class}`"
          end

          ::Gitlab::ApplicationContext.push(artifact: artifact_file)
        end

        def log_artifacts_context(job)
          ::Gitlab::ApplicationContext.push(
            namespace: job&.project&.namespace,
            project: job&.project,
            job: job
          )
        end

        def log_build_dependencies(size:, count: 0)
          ::Gitlab::ApplicationContext.push(
            artifacts_dependencies_size: size,
            artifacts_dependencies_count: count
          )
        end
      end
    end
  end
end
