class ScheduleUpdateUserActivityWorker
  include Sidekiq::Worker
  include CronjobQueue

  def perform(batch_size = 500)
    return if Gitlab::Geo.secondary?

    Gitlab::UserActivities.new.each_slice(batch_size) do |batch|
      UpdateUserActivityWorker.perform_async(Hash[batch])
    end
  end
end
