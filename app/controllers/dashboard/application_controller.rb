class Dashboard::ApplicationController < ApplicationController
  layout 'dashboard'

  private

  def projects
    @projects ||= ProjectsFinder.execute(current_user, scope: :authorized).
                                  sorted_by_activity.non_archived
  end
end
