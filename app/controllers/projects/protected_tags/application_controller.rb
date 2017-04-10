class Projects::ProtectedTags::ApplicationController < Projects::ApplicationController
  protected

  def load_protected_tag
    @protected_tag = @project.protected_tags.find(params[:protected_tag_id])
  end
end
