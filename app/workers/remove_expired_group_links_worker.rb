# frozen_string_literal: true

class RemoveExpiredGroupLinksWorker # rubocop:disable Scalability/IdempotentWorker
  include ApplicationWorker
  include CronjobQueue # rubocop:disable Scalability/CronWorkerContext

  feature_category :authentication_and_authorization

  def perform
    ProjectGroupLink.expired.find_each do |link|
      Projects::GroupLinks::DestroyService.new(link.project, nil).execute(link)
    end

    GroupGroupLink.expired.find_in_batches do |link_batch|
      Groups::GroupLinks::DestroyService.new(nil, nil).execute(link_batch)
    end
  end
end
