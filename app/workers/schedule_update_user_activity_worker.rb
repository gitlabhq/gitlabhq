class ScheduleUpdateUserActivityWorker
  include Sidekiq::Worker
  include CronjobQueue

  def perform(batch_size = 500)
<<<<<<< HEAD
    return if Gitlab::Geo.secondary?

=======
>>>>>>> ce/master
    Gitlab::UserActivities.new.each_slice(batch_size) do |batch|
      UpdateUserActivityWorker.perform_async(Hash[batch])
    end
  end
end
