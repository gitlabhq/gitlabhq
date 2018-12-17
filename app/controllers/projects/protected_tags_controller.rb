# frozen_string_literal: true

class Projects::ProtectedTagsController < Projects::ProtectedRefsController
  protected

  def project_refs
    @project.repository.tags
  end

  def service_namespace
    ::ProtectedTags
  end

  def load_protected_ref
    @protected_ref = @project.protected_tags.find(params[:id])
  end

  def access_levels
    [:create_access_levels]
  end

  def protected_ref_params
    params.require(:protected_tag).permit(:name, create_access_levels_attributes: access_level_attributes)
  end
end
