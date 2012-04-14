class SearchController < ApplicationController
  def show
    query = params[:search]
    if query.blank?
      @projects = []
      @merge_requests = []
      @issues = []
    else
      @projects = current_user.projects.search(query).limit(10)
      @merge_requests = MergeRequest.where(:project_id => current_user.project_ids).search(query).limit(10)
      @issues = Issue.where(:project_id => current_user.project_ids).search(query).limit(10)
    end
  end
end
