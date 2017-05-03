class UpdateUserActivityWorker
  include Sidekiq::Worker
  include DedicatedSidekiqQueue

  def perform(pairs)
    return if Gitlab::Geo.secondary?

    pairs = cast_data(pairs)
    ids = pairs.keys
    conditions = 'WHEN id = ? THEN ? ' * ids.length

    User.where(id: ids).
      update_all([
        "last_activity_on = CASE #{conditions} ELSE last_activity_on END",
        *pairs.to_a.flatten
      ])

    Gitlab::UserActivities.new.delete(*ids)
  end

  private

  def cast_data(pairs)
    pairs.each_with_object({}) do |(key, value), new_pairs|
      new_pairs[key.to_i] = Time.at(value.to_i).to_s(:db)
    end
  end
end
