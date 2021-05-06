# frozen_string_literal: true

module HasTimelogsReport
  extend ActiveSupport::Concern
  include Gitlab::Utils::StrongMemoize

  def timelogs(start_time, end_time)
    strong_memoize(:timelogs) { timelogs_for(start_time, end_time) }
  end

  def user_can_access_group_timelogs?(current_user)
    Ability.allowed?(current_user, :read_group_timelogs, self)
  end

  private

  def timelogs_for(start_time, end_time)
    Timelog.between_times(start_time, end_time).in_group(self)
  end
end
