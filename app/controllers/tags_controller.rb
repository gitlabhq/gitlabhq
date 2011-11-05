class TagsController < ApplicationController
	def index
		@tags = Project.tag_counts.order('count DESC')
		@tags = @tags.where('name like ?', "%#{params[:term]}%") unless params[:term].blank?

		respond_to do |format|
			format.html
			format.json { render json: @tags.limit(8).map {|t| t.name}}
		end
	end
end
