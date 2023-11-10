# frozen_string_literal: true

module RepositoryStorageMovable
  extend ActiveSupport::Concern
  include AfterCommitQueue

  included do
    scope :order_created_at_desc, -> { order(created_at: :desc) }
    scope :scheduled_or_started, -> do
      where(state: [state_machine.states[:scheduled].value, state_machine.states[:started].value])
    end

    validates :container, presence: true
    validates :state, presence: true
    validates :source_storage_name,
      on: :create,
      presence: true,
      inclusion: { in: ->(_) { Gitlab.config.repositories.storages.keys } }
    validates :destination_storage_name,
      on: :create,
      presence: true,
      inclusion: { in: ->(_) { Gitlab.config.repositories.storages.keys } }
    validate :container_repository_writable, on: :create

    attribute :destination_storage_name, default: -> { Repository.pick_storage_shard }

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

      # An after_transition can't affect the success of the transition.
      # https://gitlab.com/gitlab-org/gitlab/-/merge_requests/45160#note_431071664
      around_transition initial: :scheduled do |storage_move, block|
        block.call

        begin
          storage_move.container.set_repository_read_only!(skip_git_transfer_check: true)
        rescue StandardError => e
          storage_move.do_fail!
          storage_move.add_error(e.message)
          next false
        end

        storage_move.run_after_commit do
          storage_move.schedule_repository_storage_update_worker
        end

        true
      end

      after_transition started: :replicated do |storage_move|
        storage_move.container.set_repository_writable!

        # We have several scripts in place that replicate some statistics information
        # to other databases. Some of them depend on the updated_at column
        # to identify the models they need to extract.
        #
        # If we don't update the `updated_at` of the container after a repository storage move,
        # the scripts won't know that they need to sync them.
        #
        # See https://gitlab.com/gitlab-data/analytics/-/issues/7868
        storage_move.container.touch
      end

      before_transition started: :failed do |storage_move|
        storage_move.container.set_repository_writable!
      end

      # This callback ensures the repository is set to writable in the event of
      # a connection error during the :started -> :replicated transition
      # https://gitlab.com/gitlab-org/gitlab/-/issues/427254#note_1636072125
      before_transition replicated: :cleanup_failed do |storage_move|
        storage_move.container.set_repository_writable!
      end

      state :initial, value: 1
      state :scheduled, value: 2
      state :started, value: 3
      state :finished, value: 4
      state :failed, value: 5
      state :replicated, value: 6
      state :cleanup_failed, value: 7
    end
  end

  def schedule_repository_storage_update_worker
    raise NotImplementedError
  end

  def add_error(message)
    errors.add(error_key, message)
  end

  private

  def container_repository_writable
    add_error(_('is read-only')) if container&.repository_read_only?
  end

  def error_key
    raise NotImplementedError
  end
end
