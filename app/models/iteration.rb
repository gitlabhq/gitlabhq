# frozen_string_literal: true

class Iteration < ApplicationRecord
  self.table_name = 'sprints'

  attr_accessor :skip_future_date_validation

  STATE_ENUM_MAP = {
      upcoming: 1,
      started: 2,
      closed: 3
  }.with_indifferent_access.freeze

  include AtomicInternalId

  belongs_to :project
  belongs_to :group

  has_internal_id :iid, scope: :project, init: ->(s) { s&.project&.iterations&.maximum(:iid) }
  has_internal_id :iid, scope: :group, init: ->(s) { s&.group&.iterations&.maximum(:iid) }

  validates :start_date, presence: true
  validates :due_date, presence: true

  validate :dates_do_not_overlap, if: :start_or_due_dates_changed?
  validate :future_date, if: :start_or_due_dates_changed?, unless: :skip_future_date_validation

  scope :upcoming, -> { with_state(:upcoming) }
  scope :started, -> { with_state(:started) }

  scope :within_timeframe, -> (start_date, end_date) do
    where('start_date is not NULL or due_date is not NULL')
      .where('start_date is NULL or start_date <= ?', end_date)
      .where('due_date is NULL or due_date >= ?', start_date)
  end

  state_machine :state_enum, initial: :upcoming do
    event :start do
      transition upcoming: :started
    end

    event :close do
      transition [:upcoming, :started] => :closed
    end

    state :upcoming, value: Iteration::STATE_ENUM_MAP[:upcoming]
    state :started, value: Iteration::STATE_ENUM_MAP[:started]
    state :closed, value: Iteration::STATE_ENUM_MAP[:closed]
  end

  # Alias to state machine .with_state_enum method
  # This needs to be defined after the state machine block to avoid errors
  class << self
    alias_method :with_state, :with_state_enum
    alias_method :with_states, :with_state_enums

    def filter_by_state(iterations, state)
      case state
      when 'closed' then iterations.closed
      when 'started' then iterations.started
      when 'opened' then iterations.started.or(iterations.upcoming)
      when 'all' then iterations
      else iterations.upcoming
      end
    end

    def reference_prefix
      '*iteration:'
    end

    def reference_pattern
      nil
    end
  end

  def state
    STATE_ENUM_MAP.key(state_enum)
  end

  def state=(value)
    self.state_enum = STATE_ENUM_MAP[value]
  end

  def resource_parent
    group || project
  end

  private

  def start_or_due_dates_changed?
    start_date_changed? || due_date_changed?
  end

  # ensure dates do not overlap with other Iterations in the same group/project
  def dates_do_not_overlap
    return unless resource_parent.iterations.within_timeframe(start_date, due_date).exists?

    errors.add(:base, s_("Iteration|Dates cannot overlap with other existing Iterations"))
  end

  # ensure dates are in the future
  def future_date
    if start_date_changed?
      errors.add(:start_date, s_("Iteration|cannot be in the past")) if start_date < Date.current
      errors.add(:start_date, s_("Iteration|cannot be more than 500 years in the future")) if start_date > 500.years.from_now
    end

    if due_date_changed?
      errors.add(:due_date, s_("Iteration|cannot be in the past")) if due_date < Date.current
      errors.add(:due_date, s_("Iteration|cannot be more than 500 years in the future")) if due_date > 500.years.from_now
    end
  end
end

Iteration.prepend_if_ee('EE::Iteration')
