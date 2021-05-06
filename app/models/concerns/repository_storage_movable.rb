# frozen_string_literal: true

module RepositoryStorageMovable
  extend ActiveSupport::Concern
  include AfterCommitQueue

  included do
    scope :order_created_at_desc, -> { order(created_at: :desc) }

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

    default_value_for(:destination_storage_name, allows_nil: false) do
      Repository.pick_storage_shard
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
          storage_move.container.set_repository_read_only!(skip_git_transfer_check: true)
        rescue StandardError => err
          storage_move.add_error(err.message)
          next false
        end

        storage_move.run_after_commit do
          storage_move.schedule_repository_storage_update_worker
        end

        true
      end

      before_transition started: :replicated do |storage_move|
        storage_move.container.set_repository_writable!

        storage_move.update_repository_storage(storage_move.destination_storage_name)
      end

      after_transition started: :replicated do |storage_move|
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

      state :initial, value: 1
      state :scheduled, value: 2
      state :started, value: 3
      state :finished, value: 4
      state :failed, value: 5
      state :replicated, value: 6
      state :cleanup_failed, value: 7
    end
  end

  # Projects, snippets, and group wikis has different db structure. In projects,
  # we need to update some columns in this step, but we don't with the other resources.
  #
  # Therefore, we create this No-op method for snippets and wikis and let project
  # overwrite it in their implementation.
  def update_repository_storage(new_storage)
    # No-op
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
