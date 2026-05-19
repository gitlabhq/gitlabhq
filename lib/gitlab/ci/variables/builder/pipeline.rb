# frozen_string_literal: true

module Gitlab
  module Ci
    module Variables
      class Builder
        class Pipeline
          include Gitlab::Utils::StrongMemoize
          include GitHelper

          MAX_COMMIT_MESSAGE_SIZE_IN_BYTES = ENV.fetch('GITLAB_CI_MAX_COMMIT_MESSAGE_SIZE_IN_BYTES', 100_000)
                                                .to_i
                                                .clamp(0, 1_000_000)

          def initialize(pipeline)
            @pipeline = pipeline
          end

          def predefined_variables
            Gitlab::Ci::Variables::Collection.new.tap do |variables|
              variables.concat(predefined_pipeline_variables)

              variables.concat(predefined_commit_variables) if pipeline.sha.present?
              variables.concat(predefined_commit_tag_variables) if pipeline.tag?
              variables.concat(predefined_merge_request_variables) if pipeline.merge_request?
              variables.concat(predefined_upstream_variables) if pipeline.source_pipeline&.source_bridge.present?

              append_variable(variables, key: 'CI_OPEN_MERGE_REQUESTS') do
                refs = pipeline.open_merge_requests_refs
                refs.join(',') if refs.any?
              end

              variables.append(key: 'CI_GITLAB_FIPS_MODE', value: 'true') if Gitlab::FIPS.enabled?

              append_variable(variables, key: 'CI_KUBERNETES_ACTIVE') { 'true' if pipeline.has_kubernetes_active? }
              append_variable(variables, key: 'CI_DEPLOY_FREEZE') { 'true' if pipeline.freeze_period? }

              if pipeline.external_pull_request_event? && pipeline.external_pull_request
                variables.concat(pipeline.external_pull_request.predefined_variables)
              end
            end
          end

          private

          attr_reader :pipeline

          def predefined_pipeline_variables
            Gitlab::Ci::Variables::Collection.new.tap do |variables|
              variables.append(key: 'CI_PIPELINE_IID', value: pipeline.iid.to_s)
              variables.append(key: 'CI_PIPELINE_SOURCE', value: pipeline.source.to_s)
              variables.append(key: 'CI_PIPELINE_CREATED_AT', value: pipeline.created_at&.iso8601)
              variables.append(key: 'CI_PIPELINE_NAME', value: pipeline.name)

              if pipeline.pipeline_schedule
                variables.append(key: 'CI_PIPELINE_SCHEDULE_DESCRIPTION', value: pipeline.pipeline_schedule.description)
              end

              if pipeline.source_ref_path.present?
                variables.append(key: 'CI_CONFIG_REF_URI', value: pipeline.ci_config_ref_uri)
              end
            end
          end

          def predefined_commit_variables
            Gitlab::Ci::Variables::Collection.new.tap do |variables|
              next variables unless pipeline.sha.present?

              variables.append(key: 'CI_COMMIT_SHA', value: pipeline.sha)
              variables.append(key: 'CI_COMMIT_SHORT_SHA', value: pipeline.short_sha)
              variables.append(key: 'CI_COMMIT_BEFORE_SHA', value: pipeline.before_sha)
              variables.append(key: 'CI_COMMIT_REF_NAME', value: pipeline.source_ref)
              variables.append(key: 'CI_COMMIT_REF_SLUG', value: pipeline.source_ref_slug)
              variables.append(key: 'CI_COMMIT_BRANCH', value: pipeline.ref) if pipeline.branch?

              append_variable(variables, key: 'CI_COMMIT_MESSAGE') { git_commit_message_truncated }
              append_variable(variables, key: 'CI_COMMIT_MESSAGE_IS_TRUNCATED') { git_commit_message_truncated?.to_s }
              append_variable(variables, key: 'CI_COMMIT_TITLE') { git_commit_title_truncated }
              append_variable(variables, key: 'CI_COMMIT_DESCRIPTION') { git_commit_description_truncated }
              variables.append(key: 'CI_COMMIT_REF_PROTECTED', value: (!!pipeline.protected_ref?).to_s)
              append_variable(variables, key: 'CI_COMMIT_TIMESTAMP') { pipeline.git_commit_timestamp.to_s }
              append_variable(variables, key: 'CI_COMMIT_AUTHOR') { pipeline.git_author_full_text.to_s }
              append_variable(variables, key: 'CI_COMMIT_USER_LOGIN') { pipeline.git_author_login.to_s }
            end
          end
          strong_memoize_attr :predefined_commit_variables

          def predefined_commit_tag_variables
            Gitlab::Ci::Variables::Collection.new.tap do |variables|
              append_variable(variables, key: 'CI_COMMIT_TAG') do
                pipeline.ref if git_tag
              end

              append_variable(variables, key: 'CI_COMMIT_TAG_MESSAGE') do
                next unless git_tag

                if Feature.enabled?(:strip_signature_from_ci_commit_tag_message, pipeline.project)
                  strip_signature(git_tag.message)
                else
                  git_tag.message
                end
              end
            end
          end
          strong_memoize_attr :predefined_commit_tag_variables

          def git_tag
            pipeline.project.repository.find_tag(pipeline.ref)
          end
          strong_memoize_attr :git_tag

          def predefined_merge_request_variables
            Gitlab::Ci::Variables::Collection.new.tap do |variables|
              variables.append(key: 'CI_MERGE_REQUEST_EVENT_TYPE', value: pipeline.merge_request_event_type.to_s)
              variables.append(key: 'CI_MERGE_REQUEST_SOURCE_BRANCH_SHA', value: pipeline.source_sha.to_s)
              variables.append(key: 'CI_MERGE_REQUEST_TARGET_BRANCH_SHA', value: pipeline.target_sha.to_s)

              if merge_request_diff.present?
                variables.append(key: 'CI_MERGE_REQUEST_DIFF_ID', value: merge_request_diff.id.to_s)
                variables.append(key: 'CI_MERGE_REQUEST_DIFF_BASE_SHA', value: merge_request_diff.base_commit_sha)
              end

              variables.concat(pipeline.merge_request.predefined_variables)
            end
          end
          strong_memoize_attr :predefined_merge_request_variables

          def predefined_upstream_variables
            Gitlab::Ci::Variables::Collection.new.tap do |variables|
              variables.append(key: 'CI_UPSTREAM_PIPELINE_ID', value: pipeline.source_pipeline.source_pipeline_id.to_s)
              variables.append(key: 'CI_UPSTREAM_PROJECT_ID', value: pipeline.source_pipeline.source_project_id.to_s)
              variables.append(key: 'CI_UPSTREAM_JOB_ID', value: pipeline.source_pipeline.source_job_id.to_s)
            end
          end
          strong_memoize_attr :predefined_upstream_variables

          def merge_request_diff
            pipeline.merge_request_diff
          end
          strong_memoize_attr :merge_request_diff

          def git_commit_message_truncated
            return git_commit_message unless git_commit_message_truncated?

            truncate_in_bytes(git_commit_message, MAX_COMMIT_MESSAGE_SIZE_IN_BYTES)
          end

          def git_commit_title_truncated
            return git_commit_full_title unless git_commit_message_truncated?

            truncate_in_bytes(git_commit_full_title, MAX_COMMIT_MESSAGE_SIZE_IN_BYTES)
          end

          def git_commit_description_truncated
            return git_commit_description unless git_commit_message_truncated?

            truncate_in_bytes(git_commit_description, MAX_COMMIT_MESSAGE_SIZE_IN_BYTES)
          end

          def git_commit_message_truncated?
            git_commit_message.bytesize > MAX_COMMIT_MESSAGE_SIZE_IN_BYTES
          end
          strong_memoize_attr :git_commit_message_truncated?

          def git_commit_message
            pipeline.git_commit_message.to_s
          end
          strong_memoize_attr :git_commit_message

          def git_commit_full_title
            pipeline.git_commit_full_title.to_s
          end
          strong_memoize_attr :git_commit_full_title

          def git_commit_description
            pipeline.git_commit_description.to_s
          end
          strong_memoize_attr :git_commit_description

          def truncate_in_bytes(text, max_size)
            text.byteslice(0, max_size)
          end

          def append_variable(variables, key:, &block)
            variables.append(key: key, lazy: true, value: block)
          end
        end
      end
    end
  end
end
