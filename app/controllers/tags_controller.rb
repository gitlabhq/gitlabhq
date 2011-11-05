class TagsController < ApplicationController
	def index
	end

	def autocomplete
		tags = Project.tag_counts.limit 8
		tags = tags.where('name like ?', "%#{params[:term]}%") unless params[:term].blank?
		tags = tags.map {|t| t.name}

		respond_to do |format|
			format.json { render json: tags}
		end
	end

end
