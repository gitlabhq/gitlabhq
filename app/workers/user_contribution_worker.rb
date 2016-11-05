class UserContributionWorker
  include Sidekiq::Worker
  include CronjobQueue

  def perform(date = Date.today)
    date = Date.parse(date) if date.is_a?(String)
    Rails.logger.info("Calculating user contributions for #{date}")

    UserContribution.calculate_for(date)
  end
end
