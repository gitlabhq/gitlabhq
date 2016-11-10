module RequestAwareEntity
  extend ActiveSupport::Concern

  included do
    include Gitlab::Routing.url_helpers
  end

  def request
    @options.fetch(:request)
  end

  def current_user
    @options.fetch(:current_user)
  end

  def can?(object, action, subject)
    Ability.allowed?(object, action, subject)
  end
end
