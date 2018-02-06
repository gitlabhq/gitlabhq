# rubocop:disable Migration/UpdateLargeTable
class MigrateUserActivitiesToUsersLastActivityOn < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  disable_ddl_transaction!

  DOWNTIME = false
  USER_ACTIVITY_SET_KEY = 'user/activities'.freeze
  ACTIVITIES_PER_PAGE = 100
  TIME_WHEN_ACTIVITY_SET_WAS_INTRODUCED = Time.utc(2016, 12, 1)

  def up
    return if activities_count(TIME_WHEN_ACTIVITY_SET_WAS_INTRODUCED, Time.now).zero?

    day = Time.at(activities(TIME_WHEN_ACTIVITY_SET_WAS_INTRODUCED, Time.now).first.second)

    transaction do
      while day <= Time.now.utc.tomorrow
        persist_last_activity_on(day: day)
        day = day.tomorrow
      end
    end
  end

  def down
    # This ensures we don't lock all users for the duration of the migration.
    update_column_in_batches(:users, :last_activity_on, nil) do |table, query|
      query.where(table[:last_activity_on].not_eq(nil))
    end
  end

  private

  def persist_last_activity_on(day:, page: 1)
    activities_count = activities_count(day.at_beginning_of_day, day.at_end_of_day)

    return if activities_count.zero?

    activities = activities(day.at_beginning_of_day, day.at_end_of_day, page: page)

    update_sql =
      Arel::UpdateManager.new(ActiveRecord::Base)
        .table(users_table)
        .set(users_table[:last_activity_on] => day.to_date)
        .where(users_table[:username].in(activities.map(&:first)))
        .to_sql

    connection.exec_update(update_sql, self.class.name, [])

    unless last_page?(page, activities_count)
      persist_last_activity_on(day: day, page: page + 1)
    end
  end

  def users_table
    @users_table ||= Arel::Table.new(:users)
  end

  def activities(from, to, page: 1)
    Gitlab::Redis::SharedState.with do |redis|
      redis.zrangebyscore(USER_ACTIVITY_SET_KEY, from.to_i, to.to_i,
        with_scores: true,
        limit: limit(page))
    end
  end

  def activities_count(from, to)
    Gitlab::Redis::SharedState.with do |redis|
      redis.zcount(USER_ACTIVITY_SET_KEY, from.to_i, to.to_i)
    end
  end

  def limit(page)
    [offset(page), ACTIVITIES_PER_PAGE]
  end

  def total_pages(count)
    (count.to_f / ACTIVITIES_PER_PAGE).ceil
  end

  def last_page?(page, count)
    page >= total_pages(count)
  end

  def offset(page)
    (page - 1) * ACTIVITIES_PER_PAGE
  end
end
