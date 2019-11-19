# frozen_string_literal: true

class RemoveExpiredGroupLinksWorker
  include ApplicationWorker
  include CronjobQueue

  feature_category :authentication_and_authorization

  def perform
    ProjectGroupLink.expired.destroy_all # rubocop: disable DestroyAll

    GroupGroupLink.expired.find_in_batches do |link_batch|
      Groups::GroupLinks::DestroyService.new(nil, nil).execute(link_batch)
    end
  end
end
