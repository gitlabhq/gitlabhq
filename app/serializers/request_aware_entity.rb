module RequestAwareEntity
  extend ActiveSupport::Concern

  included do
    GitlabRoutingHelper.require_gitlab_routing(self)
    include GitlabRoutingHelper
    include Gitlab::Allowable
  end

  def request
    options.fetch(:request)
  end
end
