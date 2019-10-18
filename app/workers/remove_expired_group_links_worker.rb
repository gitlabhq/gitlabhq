# frozen_string_literal: true

class RemoveExpiredGroupLinksWorker
  include ApplicationWorker
  include CronjobQueue

  feature_category :authentication_and_authorization

  def perform
    ProjectGroupLink.expired.destroy_all # rubocop: disable DestroyAll
  end
end
