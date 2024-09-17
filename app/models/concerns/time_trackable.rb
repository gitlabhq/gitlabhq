# frozen_string_literal: true

# == TimeTrackable concern
#
# Contains functionality related to objects that support time tracking.
#
# Used by Issue and MergeRequest.
#

module TimeTrackable
  extend ActiveSupport::Concern

  include Gitlab::Utils::StrongMemoize

  included do
    attr_reader :time_spent, :time_spent_user, :spent_at, :summary

    alias_method :time_spent?, :time_spent

    validate :check_time_estimate
    validate :check_negative_time_spent

    has_many :timelogs, dependent: :destroy, autosave: true # rubocop:disable Cop/ActiveRecordDependent
    before_save :set_time_estimate_default_value
    after_save :clear_memoized_total_time_spent
  end

  def clear_memoized_total_time_spent
    clear_memoization(:total_time_spent)
  end

  def reset
    clear_memoized_total_time_spent

    super
  end

  def reload(*args)
    clear_memoized_total_time_spent

    super(*args)
  end

  # rubocop:disable Gitlab/ModuleWithInstanceVariables
  def spend_time(options)
    @time_spent = options[:duration]
    @time_spent_note_id = options[:note_id]
    @time_spent_user = User.find(options[:user_id])
    @spent_at = options[:spent_at]
    @summary = options[:summary]
    @original_total_time_spent = nil
    @category_id = category_id(options[:category])

    return if @time_spent == 0

    @timelog = if @time_spent == :reset
                 reset_spent_time
               else
                 add_or_subtract_spent_time
               end
  end
  alias_method :spend_time=, :spend_time
  # rubocop:enable Gitlab/ModuleWithInstanceVariables

  def total_time_spent
    sum = timelogs.sum(:time_spent)

    # A new restriction has been introduced to limit total time spent to -
    # Timelog::MAX_TOTAL_TIME_SPENT or 3.154e+7 seconds (approximately a year, a generous limit)
    # Since there could be existing records that breach the limit, check and return the maximum/minimum allowed value.
    # (some issuable might have total time spent that's negative because a validation was missing.)
    sum.clamp(-Timelog::MAX_TOTAL_TIME_SPENT, Timelog::MAX_TOTAL_TIME_SPENT)
  end
  strong_memoize_attr :total_time_spent

  def human_total_time_spent
    Gitlab::TimeTrackingFormatter.output(total_time_spent)
  end

  def time_change
    @timelog&.time_spent.to_i # rubocop:disable Gitlab/ModuleWithInstanceVariables
  end

  def human_time_change
    Gitlab::TimeTrackingFormatter.output(time_change)
  end

  def human_time_estimate
    Gitlab::TimeTrackingFormatter.output(time_estimate)
  end

  def time_estimate=(val)
    val.is_a?(Integer) ? super([val, Gitlab::Database::MAX_INT_VALUE].min) : super(val)
  end

  def time_estimate
    super || self.class.column_defaults['time_estimate']
  end

  def set_time_estimate_default_value
    return if new_record?
    return unless has_attribute?(:time_estimate)
    # time estimate can be set to nil, in case of an invalid value, e.g. a String instead of a number, in which case
    # we should not be overwriting it to default value, but rather have the validation catch the error
    return if time_estimate_changed?

    self.time_estimate = self.class.column_defaults['time_estimate'] if read_attribute(:time_estimate).nil?
  end

  private

  def reset_spent_time
    timelogs.new(time_spent: total_time_spent * -1, user: @time_spent_user) # rubocop:disable Gitlab/ModuleWithInstanceVariables
  end

  # rubocop:disable Gitlab/ModuleWithInstanceVariables
  def add_or_subtract_spent_time
    timelogs.new(
      time_spent: time_spent,
      note_id: @time_spent_note_id,
      user: @time_spent_user,
      spent_at: @spent_at,
      summary: @summary,
      timelog_category_id: @category_id
    )
  end
  # rubocop:enable Gitlab/ModuleWithInstanceVariables

  def check_negative_time_spent
    return if time_spent.nil? || time_spent == :reset

    if time_spent < 0 && (time_spent.abs > original_total_time_spent)
      errors.add(:base, _('Time to subtract exceeds the total time spent'))
    end
  end

  # we need to cache the total time spent so multiple calls to #valid?
  # doesn't give a false error
  def original_total_time_spent
    @original_total_time_spent ||= total_time_spent
  end

  def check_time_estimate
    # we'll set the time_tracking to zero at DB level through default value
    return unless time_estimate_changed?
    return if read_attribute(:time_estimate).is_a?(Numeric) && read_attribute(:time_estimate) >= 0

    errors.add(:time_estimate, _('must have a valid format and be greater than or equal to zero.'))
  end

  def category_id(category)
    TimeTracking::TimelogCategory.find_by_name(project&.root_namespace, category).first&.id
  end
end
