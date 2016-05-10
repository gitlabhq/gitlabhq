class Dashboard::ApplicationController < ApplicationController
  layout 'dashboard'

  private

  def projects
    @projects ||= ProjectsFinder.new.execute(current_user).sorted_by_activity.non_archived
  end
end
