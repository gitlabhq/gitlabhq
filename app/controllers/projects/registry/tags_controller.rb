# frozen_string_literal: true

module Projects
  module Registry
    class TagsController < ::Projects::Registry::ApplicationController
      before_action :authorize_destroy_container_image!, only: [:destroy]

      def index
        respond_to do |format|
          format.json do
            render json: ContainerTagsSerializer
              .new(project: @project, current_user: @current_user)
              .with_pagination(request, response)
              .represent(tags)
          end
        end
      end

      def destroy
        if tag.delete
          respond_to do |format|
            format.json { head :no_content }
          end
        else
          respond_to do |format|
            format.json { head :bad_request }
          end
        end
      end

      def bulk_destroy
        @tags = (params[:ids] || []).map { |tag_name| image.tag(tag_name) }

        success_count = 0
        @tags.each do |tag|
          if tag.delete
            success_count += 1
          end
        end

        respond_to do |format|
          format.json { head(success_count == @tags.size ? :no_content : :bad_request) }
        end
      end

      private

      def tags
        Kaminari::PaginatableArray.new(image.tags, limit: 15)
      end

      def image
        @image ||= project.container_repositories
          .find(params[:repository_id])
      end

      def tag
        @tag ||= image.tag(params[:id])
      end
    end
  end
end
