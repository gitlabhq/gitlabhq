class UserIssuesController < ApplicationController
  before_filter :authenticate_user!

  respond_to :js, :html

  def index
    @projects = current_user.projects.all
    @user   = current_user
    @issues = current_user.assigned_issues.opened

    @issues = @issues.includes(:author, :project)

    respond_to do |format|
      format.html
      format.js
      format.atom { render :layout => false }
    end
  end

end
