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

  default_value_for(:destination_storage_name, allows_nil: false) do
    pick_repository_storage
  end

  state_machine initial: :initial do
    event :schedule do
      transition initial: :scheduled
    end

    event :start do
      transition scheduled: :started
    end

    event :finish_replication do
      transition started: :replicated
    end

    event :finish_cleanup do
      transition replicated: :finished
    end

    event :do_fail do
      transition [:initial, :scheduled, :started] => :failed
      transition replicated: :cleanup_failed
    end

    around_transition initial: :scheduled do |storage_move, block|
      block.call

      begin
        storage_move.project.set_repository_read_only!(skip_git_transfer_check: true)
      rescue => err
        errors.add(:project, err.message)
        next false
      end

      storage_move.run_after_commit do
        ProjectUpdateRepositoryStorageWorker.perform_async(
          storage_move.project_id,
          storage_move.destination_storage_name,
          storage_move.id
        )
      end

      true
    end

    before_transition started: :replicated do |storage_move|
      storage_move.project.set_repository_writable!

      storage_move.project.update_column(:repository_storage, storage_move.destination_storage_name)
    end

    before_transition started: :failed do |storage_move|
      storage_move.project.set_repository_writable!
    end

    state :initial, value: 1
    state :scheduled, value: 2
    state :started, value: 3
    state :finished, value: 4
    state :failed, value: 5
    state :replicated, value: 6
    state :cleanup_failed, value: 7
  end

  scope :order_created_at_desc, -> { order(created_at: :desc) }
  scope :with_projects, -> { includes(project: :route) }

  class << self
    def pick_repository_storage
      Project.pick_repository_storage
    end
  end

  private

  def project_repository_writable
    errors.add(:project, _('is read only')) if project&.repository_read_only?
  end
end
