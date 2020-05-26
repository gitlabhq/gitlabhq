# frozen_string_literal: true

# ProjectRepositoryStorageMove are details of repository storage moves for a
# project. For example, moving a project to another gitaly node to help
# balance storage capacity.
class ProjectRepositoryStorageMove < ApplicationRecord
  include AfterCommitQueue

  belongs_to :project, inverse_of: :repository_storage_moves

  validates :project, presence: true
  validates :state, presence: true
  validates :source_storage_name,
    on: :create,
    presence: true,
    inclusion: { in: ->(_) { Gitlab.config.repositories.storages.keys } }
  validates :destination_storage_name,
    on: :create,
    presence: true,
    inclusion: { in: ->(_) { Gitlab.config.repositories.storages.keys } }
  validate :project_repository_writable, on: :create

  state_machine initial: :initial do
    event :schedule do
      transition initial: :scheduled
    end

    event :start do
      transition scheduled: :started
    end

    event :finish do
      transition started: :finished
    end

    event :do_fail do
      transition [:initial, :scheduled, :started] => :failed
    end

    after_transition initial: :scheduled do |storage_move|
      storage_move.project.update_column(:repository_read_only, true)

      storage_move.run_after_commit do
        ProjectUpdateRepositoryStorageWorker.perform_async(
          storage_move.project_id,
          storage_move.destination_storage_name,
          storage_move.id
        )
      end
    end

    after_transition started: :finished do |storage_move|
      storage_move.project.update_columns(
        repository_read_only: false,
        repository_storage: storage_move.destination_storage_name
      )
    end

    after_transition started: :failed do |storage_move|
      storage_move.project.update_column(:repository_read_only, false)
    end

    state :initial, value: 1
    state :scheduled, value: 2
    state :started, value: 3
    state :finished, value: 4
    state :failed, value: 5
  end

  scope :order_created_at_desc, -> { order(created_at: :desc) }
  scope :with_projects, -> { includes(project: :route) }

  private

  def project_repository_writable
    errors.add(:project, _('is read only')) if project&.repository_read_only?
  end
end
