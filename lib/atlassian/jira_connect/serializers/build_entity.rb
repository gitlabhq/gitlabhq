# frozen_string_literal: true

module Atlassian
  module JiraConnect
    module Serializers
      # A Jira 'build' represents what we call a 'pipeline'
      class BuildEntity < Grape::Entity
        include Gitlab::Routing

        format_with(:iso8601, &:iso8601)

        expose :schema_version, as: :schemaVersion
        expose :pipeline_id, as: :pipelineId
        expose :iid, as: :buildNumber
        expose :update_sequence_id, as: :updateSequenceNumber
        expose :source_ref, as: :displayName
        expose :url
        expose :state
        expose :updated_at, as: :lastUpdated, format_with: :iso8601
        expose :issue_keys, as: :issueKeys
        expose :test_info, as: :testInfo
        expose :references

        def issue_keys
          @issue_keys ||= (pipeline_commit_issue_keys + pipeline_mrs_issue_keys).uniq
        end

        private

        alias_method :pipeline, :object
        delegate :project, to: :object

        def url
          project_pipeline_url(project, pipeline)
        end

        # translate to Jira status
        def state
          case pipeline.status
          when 'scheduled', 'created', 'pending', 'preparing', 'waiting_for_resource' then 'pending'
          when 'running' then 'in_progress'
          when 'success' then 'successful'
          when 'failed' then 'failed'
          when 'canceled', 'skipped' then 'cancelled'
          else
            'unknown'
          end
        end

        def pipeline_id
          pipeline.ensure_ci_ref!

          pipeline.ci_ref.id.to_s
        end

        def schema_version
          '1.0'
        end

        def test_info
          builds = pipeline.builds.pluck(:status) # rubocop: disable CodeReuse/ActiveRecord
          n = builds.size
          passed = builds.count { |s| s == 'success' }
          failed = builds.count { |s| s == 'failed' }

          {
            totalNumber: n,
            numberPassed: passed,
            numberFailed: failed,
            numberSkipped: n - (passed + failed)
          }
        end

        def references
          ref = pipeline.source_ref

          [{
            commit: { id: pipeline.sha, repositoryUri: project_url(project) },
            ref: { name: ref, uri: project_commits_url(project, ref) }
          }]
        end

        def update_sequence_id
          options[:update_sequence_id] || Client.generate_update_sequence_id
        end

        def pipeline_commit_issue_keys
          JiraIssueKeyExtractor.new(pipeline.git_commit_message).issue_keys
        end

        # Extract Jira issue keys from either the source branch/ref, merge request title or merge request description.
        def pipeline_mrs_issue_keys
          pipeline.all_merge_requests.flat_map do |mr|
            src = "#{mr.source_branch} #{mr.title} #{mr.description}"
            JiraIssueKeyExtractor.new(src).issue_keys
          end
        end
      end
    end
  end
end
