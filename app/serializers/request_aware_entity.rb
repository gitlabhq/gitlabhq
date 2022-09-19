# frozen_string_literal: true

module RequestAwareEntity
  extend ActiveSupport::Concern

  included do
    include Gitlab::Routing
    include GitlabRoutingHelper
    include Gitlab::Allowable
  end

  def request
    options.fetch(:request, nil)
  end
end
