# frozen_string_literal: true

module Integrations
  module ProjectTestData
    private

    def push_events_data
      Gitlab::DataBuilder::Push.build_sample(project, current_user)
    end

    def use_newest_record?
      Feature.enabled?(:integrations_test_webhook_reorder, project)
    end

    def note_events_data
      note = NotesFinder.new(current_user, project: project, target: project).execute.reorder(nil).last # rubocop: disable CodeReuse/ActiveRecord

      return { error: s_('TestHooks|Ensure the project has notes.') } unless note.present?

      Gitlab::DataBuilder::Note.build(note, current_user)
    end

    def issues_events_data
      issue = IssuesFinder.new(current_user, project_id: project.id, sort: 'created_desc').execute.first

      return { error: s_('TestHooks|Ensure the project has issues.') } unless issue.present?

      issue.to_hook_data(current_user)
    end

    def merge_requests_events_data
      merge_request = MergeRequestsFinder.new(current_user, project_id: project.id, sort: 'created_desc').execute.first

      return { error: s_('TestHooks|Ensure the project has merge requests.') } unless merge_request.present?

      merge_request.to_hook_data(current_user)
    end

    def job_events_data
      build = if use_newest_record?
                Ci::JobsFinder.new(current_user: current_user, project: project).execute.first
              else
                project.builds.first
              end

      return { error: s_('TestHooks|Ensure the project has CI jobs.') } unless build.present?

      Gitlab::DataBuilder::Build.build(build)
    end

    def pipeline_events_data
      pipeline = if use_newest_record?
                   Ci::PipelinesFinder.new(project, current_user, order_by: 'id', sort: 'desc').execute.first
                 else
                   project.ci_pipelines.newest_first.first
                 end

      return { error: s_('TestHooks|Ensure the project has CI pipelines.') } unless pipeline.present?

      Gitlab::DataBuilder::Pipeline.build(pipeline)
    end

    def wiki_page_events_data
      page = project.wiki.list_pages(limit: 1).first

      if !project.wiki_enabled? || page.blank?
        return { error: s_('TestHooks|Ensure the wiki is enabled and has pages.') }
      end

      Gitlab::DataBuilder::WikiPage.build(page, current_user, 'create')
    end

    def deployment_events_data
      deployment = if use_newest_record?
                     DeploymentsFinder.new(project: project, order_by: 'created_at', sort: 'desc').execute.first
                   else
                     project.deployments.first
                   end

      return { error: s_('TestHooks|Ensure the project has deployments.') } unless deployment.present?

      Gitlab::DataBuilder::Deployment.build(deployment)
    end

    def releases_events_data
      release = if use_newest_record?
                  ReleasesFinder.new(project, current_user, order_by: :created_at, sort: :desc).execute.first
                else
                  project.releases.first
                end

      return { error: s_('TestHooks|Ensure the project has releases.') } unless release.present?

      release.to_hook_data('create')
    end
  end
end
