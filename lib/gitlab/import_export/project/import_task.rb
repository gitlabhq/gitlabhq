# frozen_string_literal: true

module Gitlab
  module ImportExport
    module Project
      class ImportTask < BaseTask
        def import
          show_import_start_message

          run_isolated_sidekiq_job

          show_import_failures_count

          return error(project.import_state.last_error) if project.import_state&.last_error
          return error(project.errors.full_messages.to_sentence) if project.errors.any?

          success('Done!')
        end

        private

        # We want to ensure that all Sidekiq jobs are executed
        # synchronously as part of that process.
        # This ensures that all expensive operations do not escape
        # to general Sidekiq clusters/nodes.
        def with_isolated_sidekiq_job
          Sidekiq::Testing.fake! do
            ::Gitlab::SafeRequestStore.ensure_request_store do
              # If you are attempting to import a large project into a development environment,
              # you may see Gitaly throw an error about too many calls or invocations.
              # This is due to a n+1 calls limit being set for development setups (not enforced in production)
              # https://gitlab.com/gitlab-org/gitlab/-/merge_requests/24475#note_283090635
              # For development setups, this code-path will be excluded from n+1 detection.
              ::Gitlab::GitalyClient.allow_n_plus_1_calls do
                yield
              end
            end

            true
          end
        end

        def run_isolated_sidekiq_job
          with_isolated_sidekiq_job do
            @project = create_project

            execute_sidekiq_job
          end
        end

        def create_project
          # We are disabling ObjectStorage for `import`
          # as it is too slow to handle big archives:
          # 1. DB transaction timeouts on upload
          # 2. Download of archive before unpacking
          disable_upload_object_storage do
            service = Projects::GitlabProjectsImportService.new(
              current_user,
              import_params
            )

            service.execute
          end
        end

        def execute_sidekiq_job
          Sidekiq::Worker.drain_all # rubocop:disable Cop/SidekiqApiUsage
        end

        def full_path
          "#{namespace.full_path}/#{project_path}"
        end

        def show_import_start_message
          logger.info "Importing GitLab export: #{file_path} into GitLab " \
            "#{full_path} " \
            "as #{current_user.name}"
        end

        def import_params
          {
            namespace_id: namespace.id,
            path: project_path,
            file: File.open(file_path)
          }
        end

        def show_import_failures_count
          return unless project.import_failures.exists?

          logger.info "Total number of not imported relations: #{project.import_failures.count}"
        end
      end
    end
  end
end
