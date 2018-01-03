module ToggleSubscriptionAction
  extend ActiveSupport::Concern

  def toggle_subscription
    return unless current_user

    subscribable_resource.toggle_subscription(current_user, subscribable_project)

    head :ok
  end

  private

  def subscribable_project
    @project ||= raise(NotImplementedError)
  end

  def subscribable_resource
    raise NotImplementedError
  end
end
