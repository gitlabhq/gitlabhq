class SearchController < ApplicationController
  def show
    result = SearchContext.new(@current_user, params).execute

    @projects       = result[:projects]
    @merge_requests = result[:merge_requests]
    @issues         = result[:issues]
    @wiki_pages     = result[:wiki_pages]
    @blobs          = Kaminari.paginate_array(result[:blobs]).page(params[:page]).per(20)
    @total_results = @projects.count + @merge_requests.count + @issues.count + @wiki_pages.count + @blobs.total_count
  end
end
