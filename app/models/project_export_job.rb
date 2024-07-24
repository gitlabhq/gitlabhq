# frozen_string_literal: true

class ProjectExportJob < ApplicationRecord
  include EachBatch
  include AfterCommitQueue

  EXPIRES_IN = 7.days

  belongs_to :project
  belongs_to :user
  has_many :relation_exports, class_name: 'Projects::ImportExport::RelationExport'

  validates :project, :jid, :status, presence: true

  STATUS = {
    queued: 0,
    started: 1,
    finished: 2,
    failed: 3
  }.freeze

  scope :prunable, -> { where("updated_at < ?", EXPIRES_IN.ago) }
  scope :order_by_updated_at, -> { order(:updated_at, :id) }
  scope :by_user_id, ->(user_id) { where(user_id: user_id) }

  state_machine :status, initial: :queued do
    event :start do
      transition [:queued] => :started
    end

    event :finish do
      transition [:started] => :finished
    end

    event :fail_op do
      transition [:queued, :started] => :failed
    end

    state :queued, value: STATUS[:queued]
    state :started, value: STATUS[:started]
    state :finished, value: STATUS[:finished]
    state :failed, value: STATUS[:failed]

    after_transition any => :finished do |export_job|
      export_job.run_after_commit_or_now do
        audit_project_exported
      end
    end
  end

  private

  def audit_project_exported
    return if exported_by_admin? && Gitlab::CurrentSettings.silent_admin_exports_enabled?

    audit_context = {
      name: 'project_export_created',
      author: user,
      scope: project,
      target: project,
      message: 'Profile file export was created'
    }

    ::Gitlab::Audit::Auditor.audit(audit_context)
  end
end
