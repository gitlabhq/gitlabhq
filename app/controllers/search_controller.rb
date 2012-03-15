class SearchController < ApplicationController
  def show
    query = params[:search]
    if query.blank?
      @projects = []
      @merge_requests = []
    else
      @projects = Project.search(query).limit(10)
      @merge_requests = MergeRequest.search(query).limit(10)
    end
  end
end
