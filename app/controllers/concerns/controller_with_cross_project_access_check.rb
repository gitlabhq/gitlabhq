module ControllerWithCrossProjectAccessCheck
  extend ActiveSupport::Concern

  included do
    extend Gitlab::CrossProjectAccess::ClassMethods
    before_action :cross_project_check
  end

  def cross_project_check
    if Gitlab::CrossProjectAccess.find_check(self)&.should_run?(self)
      authorize_cross_project_page!
    end
  end

  def authorize_cross_project_page!
    return if can?(current_user, :read_cross_project)

    rejection_message = _(
      "This page is unavailable because you are not allowed to read information "\
      "across multiple projects."
    )
    access_denied!(rejection_message)
  end
end
