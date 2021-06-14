# frozen_string_literal: true

module Gitlab
  module Ci
    class Config
      module External
        module File
          class Artifact < Base
            extend ::Gitlab::Utils::Override
            include Gitlab::Utils::StrongMemoize

            attr_reader :job_name

            def initialize(params, context)
              @location = params[:artifact]
              @job_name = params[:job]

              super
            end

            def content
              strong_memoize(:content) do
                next unless artifact_job

                Gitlab::Ci::ArtifactFileReader.new(artifact_job).read(location)
              rescue Gitlab::Ci::ArtifactFileReader::Error => error
                errors.push(error.message)
              end
            end

            private

            def project
              context&.parent_pipeline&.project
            end

            def validate_content!
              return unless ensure_preconditions_satisfied!

              errors.push("File `#{location}` is empty!") unless content.present?
            end

            def ensure_preconditions_satisfied!
              unless creating_child_pipeline?
                errors.push('Including configs from artifacts is only allowed when triggering child pipelines')
                return false
              end

              unless job_name.present?
                errors.push("Job must be provided when including configs from artifacts")
                return false
              end

              unless artifact_job.present?
                errors.push("Job `#{job_name}` not found in parent pipeline or does not have artifacts!")
                return false
              end

              true
            end

            def artifact_job
              strong_memoize(:artifact_job) do
                next unless creating_child_pipeline?

                context.parent_pipeline.find_job_with_archive_artifacts(job_name)
              end
            end

            def creating_child_pipeline?
              context.parent_pipeline.present?
            end

            override :expand_context_attrs
            def expand_context_attrs
              {
                project: context.project,
                sha: context.sha,
                user: context.user,
                parent_pipeline: context.parent_pipeline
              }
            end
          end
        end
      end
    end
  end
end
