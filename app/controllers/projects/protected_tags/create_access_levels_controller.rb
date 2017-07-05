module Projects
  module ProtectedTags
    class CreateAccessLevelsController < ProtectedTags::ApplicationController
      before_action :load_protected_tag, only: [:destroy]

      def destroy
        @create_access_level = @protected_tag.create_access_levels.find(params[:id])
        @create_access_level.destroy

        redirect_to project_protected_tag_path(@project, @protected_tag),
                    status: 302,
                    notice: "Successfully deleted. #{@create_access_level.humanize} will not be able to create this protected tag."
      end
    end
  end
end
