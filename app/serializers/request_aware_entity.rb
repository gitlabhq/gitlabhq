module RequestAwareEntity
  extend ActiveSupport::Concern

  included do
    include Gitlab::Routing
    include Gitlab::Allowable
  end

  def request
    options.fetch(:request)
  end
end
