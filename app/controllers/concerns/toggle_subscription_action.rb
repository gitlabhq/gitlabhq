module ToggleSubscriptionAction
  extend ActiveSupport::Concern

  def toggle_subscription
    return unless current_user

    subscribable_resource.toggle_subscription(current_user)

    render nothing: true
  end

  private

  def subscribable_resource
    raise NotImplementedError
  end
end
