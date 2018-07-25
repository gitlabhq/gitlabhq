# frozen_string_literal: true

class ProjectImportState < ActiveRecord::Base
  include AfterCommitQueue

  self.table_name = "project_mirror_data"

  prepend EE::ProjectImportState

  belongs_to :project, inverse_of: :import_state

  validates :project, presence: true

  state_machine :status, initial: :none do
    event :schedule do
      transition [:none, :finished, :failed] => :scheduled
    end

    event :force_start do
      transition [:none, :finished, :failed] => :started
    end

    event :start do
      transition scheduled: :started
    end

    event :finish do
      transition started: :finished
    end

    event :fail_op do
      transition [:scheduled, :started] => :failed
    end

    state :scheduled
    state :started
    state :finished
    state :failed

    after_transition [:none, :finished, :failed] => :scheduled do |state, _|
      state.run_after_commit do
        job_id = project.add_import_job
        update(jid: job_id) if job_id
      end
    end

    after_transition started: :finished do |state, _|
      project = state.project

      project.reset_cache_and_import_attrs

      if Gitlab::ImportSources.importer_names.include?(project.import_type) && project.repo_exists?
        state.run_after_commit do
          Projects::AfterImportService.new(project).execute
        end
      end
    end
  end
end
