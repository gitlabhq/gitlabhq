class ScheduleUpdateUserActivityWorker
  include ApplicationWorker
  include CronjobQueue

  def perform(batch_size = 500)
    Gitlab::UserActivities.new.each_slice(batch_size) do |batch|
      UpdateUserActivityWorker.perform_async(Hash[batch])
    end
  end
end
