# frozen_string_literal: true

class GroupImportState < ApplicationRecord
  include AfterCommitQueue
  include Gitlab::InternalEventsTracking

  self.primary_key = :group_id

  MAX_ERROR_LENGTH = 255
  IMPORT_LABEL = 'gitlab_group_export'

  belongs_to :group, inverse_of: :import_state
  belongs_to :user, optional: false

  validates :group, :status, :user, presence: true
  validates :jid, presence: true, if: -> { started? || finished? }

  state_machine :status, initial: :created do
    state :created, value: 0
    state :started, value: 1
    state :finished, value: 2
    state :failed, value: -1

    event :start do
      transition created: :started
    end

    event :finish do
      transition started: :finished
    end

    event :fail_op do
      transition any => :failed
    end

    after_transition any => :failed do |state, transition|
      last_error = transition.args.first

      state.update_column(:last_error, last_error.truncate(MAX_ERROR_LENGTH)) if last_error
    end

    after_transition on: :start do |state, _|
      state.track_start_group_import
    end

    after_transition on: :finish do |state, _|
      state.track_finish_group_import
    end

    after_transition on: :fail_op do |state, _|
      state.track_fail_group_import
    end
  end

  def in_progress?
    created? || started?
  end

  def track_start_group_import
    track_group_import_event('start_group_import')
  end

  def track_finish_group_import
    track_group_import_event('finish_group_import')
  end

  def track_fail_group_import
    track_group_import_event('fail_group_import')
  end

  private

  def track_group_import_event(action)
    run_after_commit do
      track_internal_event(
        action,
        namespace: group,
        user: user,
        additional_properties: { label: IMPORT_LABEL }
      )
    end
  end
end
