# frozen_string_literal: true

module Gitlab
  module Ci
    module Variables
      class Builder
        class Pipeline
          include Gitlab::Utils::StrongMemoize

          def initialize(pipeline)
            @pipeline = pipeline
          end

          def predefined_variables
            Gitlab::Ci::Variables::Collection.new.tap do |variables|
              variables.append(key: 'CI_PIPELINE_IID', value: pipeline.iid.to_s)
              variables.append(key: 'CI_PIPELINE_SOURCE', value: pipeline.source.to_s)
              variables.append(key: 'CI_PIPELINE_CREATED_AT', value: pipeline.created_at&.iso8601)

              variables.concat(predefined_commit_variables) if pipeline.sha.present?
              variables.concat(predefined_commit_tag_variables) if pipeline.tag?
              variables.concat(predefined_merge_request_variables) if pipeline.merge_request?

              if pipeline.open_merge_requests_refs.any?
                variables.append(key: 'CI_OPEN_MERGE_REQUESTS', value: pipeline.open_merge_requests_refs.join(','))
              end

              variables.append(key: 'CI_GITLAB_FIPS_MODE', value: 'true') if Gitlab::FIPS.enabled?

              variables.append(key: 'CI_KUBERNETES_ACTIVE', value: 'true') if pipeline.has_kubernetes_active?
              variables.append(key: 'CI_DEPLOY_FREEZE', value: 'true') if pipeline.freeze_period?

              if pipeline.external_pull_request_event? && pipeline.external_pull_request
                variables.concat(pipeline.external_pull_request.predefined_variables)
              end
            end
          end

          private

          attr_reader :pipeline

          def predefined_commit_variables # rubocop:disable Metrics/AbcSize - Remove this rubocop:disable when FF `ci_remove_legacy_predefined_variables` is removed.
            Gitlab::Ci::Variables::Collection.new.tap do |variables|
              next variables unless pipeline.sha.present?

              variables.append(key: 'CI_COMMIT_SHA', value: pipeline.sha)
              variables.append(key: 'CI_COMMIT_SHORT_SHA', value: pipeline.short_sha)
              variables.append(key: 'CI_COMMIT_BEFORE_SHA', value: pipeline.before_sha)
              variables.append(key: 'CI_COMMIT_REF_NAME', value: pipeline.source_ref)
              variables.append(key: 'CI_COMMIT_REF_SLUG', value: pipeline.source_ref_slug)
              variables.append(key: 'CI_COMMIT_BRANCH', value: pipeline.ref) if pipeline.branch?
              variables.append(key: 'CI_COMMIT_MESSAGE', value: pipeline.git_commit_message.to_s)
              variables.append(key: 'CI_COMMIT_TITLE', value: pipeline.git_commit_full_title.to_s)
              variables.append(key: 'CI_COMMIT_DESCRIPTION', value: pipeline.git_commit_description.to_s)
              variables.append(key: 'CI_COMMIT_REF_PROTECTED', value: (!!pipeline.protected_ref?).to_s)
              variables.append(key: 'CI_COMMIT_TIMESTAMP', value: pipeline.git_commit_timestamp.to_s)
              variables.append(key: 'CI_COMMIT_AUTHOR', value: pipeline.git_author_full_text.to_s)

              if Feature.disabled?(:ci_remove_legacy_predefined_variables, pipeline.project)
                variables.concat(legacy_predefined_commit_variables)
              end
            end
          end
          strong_memoize_attr :predefined_commit_variables

          def legacy_predefined_commit_variables
            Gitlab::Ci::Variables::Collection.new.tap do |variables|
              variables.append(key: 'CI_BUILD_REF', value: pipeline.sha)
              variables.append(key: 'CI_BUILD_BEFORE_SHA', value: pipeline.before_sha)
              variables.append(key: 'CI_BUILD_REF_NAME', value: pipeline.source_ref)
              variables.append(key: 'CI_BUILD_REF_SLUG', value: pipeline.source_ref_slug)
            end
          end
          strong_memoize_attr :legacy_predefined_commit_variables

          def predefined_commit_tag_variables
            Gitlab::Ci::Variables::Collection.new.tap do |variables|
              git_tag = pipeline.project.repository.find_tag(pipeline.ref)

              next variables unless git_tag

              variables.append(key: 'CI_COMMIT_TAG', value: pipeline.ref)
              variables.append(key: 'CI_COMMIT_TAG_MESSAGE', value: git_tag.message)

              if Feature.disabled?(:ci_remove_legacy_predefined_variables, pipeline.project)
                variables.concat(legacy_predefined_commit_tag_variables)
              end
            end
          end
          strong_memoize_attr :predefined_commit_tag_variables

          def legacy_predefined_commit_tag_variables
            Gitlab::Ci::Variables::Collection.new.tap do |variables|
              variables.append(key: 'CI_BUILD_TAG', value: pipeline.ref)
            end
          end
          strong_memoize_attr :legacy_predefined_commit_tag_variables

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

          def merge_request_diff
            pipeline.merge_request_diff
          end
          strong_memoize_attr :merge_request_diff
        end
      end
    end
  end
end
