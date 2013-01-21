class SearchController < ApplicationController
  def show
    result = SearchContext.new(current_user.authorized_projects.map(&:id), params).execute

    @projects       = result[:projects]
    @merge_requests = result[:merge_requests]
    @issues         = result[:issues]
    @wiki_pages     = result[:wiki_pages]
  end
end
