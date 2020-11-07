# frozen_string_literal: true

module Integrations
  module ProjectTestData
    private

    def push_events_data
      Gitlab::DataBuilder::Push.build_sample(project, current_user)
    end

    def note_events_data
      note = project.notes.first
      return { error: s_('TestHooks|Ensure the project has notes.') } unless note.present?

      Gitlab::DataBuilder::Note.build(note, current_user)
    end

    def issues_events_data
      issue = project.issues.first
      return { error: s_('TestHooks|Ensure the project has issues.') } unless issue.present?

      issue.to_hook_data(current_user)
    end

    def merge_requests_events_data
      merge_request = project.merge_requests.first
      return { error: s_('TestHooks|Ensure the project has merge requests.') } unless merge_request.present?

      merge_request.to_hook_data(current_user)
    end

    def job_events_data
      build = project.builds.first
      return { error: s_('TestHooks|Ensure the project has CI jobs.') } unless build.present?

      Gitlab::DataBuilder::Build.build(build)
    end

    def pipeline_events_data
      pipeline = project.ci_pipelines.newest_first.first
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
      deployment = project.deployments.first
      return { error: s_('TestHooks|Ensure the project has deployments.') } unless deployment.present?

      Gitlab::DataBuilder::Deployment.build(deployment)
    end

    def releases_events_data
      release = project.releases.first
      return { error: s_('TestHooks|Ensure the project has releases.') } unless release.present?

      release.to_hook_data('create')
    end
  end
end
