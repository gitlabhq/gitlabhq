module Projects
  module Registry
    class TagsController < ::Projects::Registry::ApplicationController
      before_action :authorize_update_container_image!, only: [:destroy]

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
