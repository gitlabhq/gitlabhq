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
              return unless context.parent_pipeline.present?

              # We define max archive size to be equal to content size
              # as a good enough approximation to provide a sane limit with a single setting
              max_content_size = Gitlab::CurrentSettings.current_application_settings.max_artifacts_content_include_size
              file_reader = Gitlab::Ci::ArtifactFileReader.new(artifact_job, max_archive_size: max_content_size)
              file_reader.read(location, max_size: max_content_size)

            rescue Gitlab::Ci::ArtifactFileReader::Error => error
              errors.push(error.message)

              nil
            end
            strong_memoize_attr :content

            def metadata
              super.merge(
                type: :artifact,
                location: masked_location,
                extra: { job_name: masked_job_name }
              )
            end

            def validate_context!
              context.logger.instrument(:config_file_artifact_validate_context) do
                if !creating_child_pipeline?
                  errors.push('Including configs from artifacts is only allowed when triggering child pipelines')
                elsif !job_name.present?
                  errors.push("Job must be provided when including configs from artifacts")
                elsif !artifact_job.present?
                  errors.push("Job `#{masked_job_name}` not found in parent pipeline or does not have artifacts!")
                end
              end
            end

            def validate_content!
              errors.push("File `#{masked_location}` is empty!") unless content.present?
            end

            private

            def artifact_job
              strong_memoize(:artifact_job) do
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

            def masked_job_name
              strong_memoize(:masked_job_name) do
                context.mask_variables_from(job_name)
              end
            end
          end
        end
      end
    end
  end
end
