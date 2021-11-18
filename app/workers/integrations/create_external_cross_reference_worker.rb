# frozen_string_literal: true

module Integrations
  class CreateExternalCrossReferenceWorker
    include ApplicationWorker

    data_consistency :delayed

    feature_category :integrations
    urgency :low
    idempotent!
    deduplicate :until_executed, including_scheduled: true
    loggable_arguments 2

    def perform(project_id, external_issue_id, mentionable_type, mentionable_id, author_id)
      project = Project.find_by_id(project_id) || return
      author = User.find_by_id(author_id) || return
      mentionable = find_mentionable(mentionable_type, mentionable_id, project) || return
      external_issue = ExternalIssue.new(external_issue_id, project)

      project.external_issue_tracker.create_cross_reference_note(
        external_issue,
        mentionable,
        author
      )
    end

    private

    def find_mentionable(mentionable_type, mentionable_id, project)
      mentionable_class = mentionable_type.safe_constantize

      # Passing an invalid mentionable_class is a developer error, so we don't want to retry the job
      # but still track the exception on production, and raise it in development.
      unless mentionable_class && mentionable_class < Mentionable
        Gitlab::ErrorTracking.track_and_raise_for_dev_exception(ArgumentError.new("Unexpected class '#{mentionable_type}' is not a Mentionable"))
        return
      end

      if mentionable_type == 'Commit'
        project.commit(mentionable_id)
      else
        mentionable_class.find_by_id(mentionable_id)
      end
    end
  end
end
