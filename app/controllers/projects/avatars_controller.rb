# frozen_string_literal: true

class Projects::AvatarsController < Projects::ApplicationController
  include SendsBlob

  skip_before_action :default_cache_headers, only: :show

  before_action :authorize_admin_project!, only: [:destroy]

  feature_category :projects

  def show
    @blob = @repository.blob_at_branch(@repository.root_ref, @project.avatar_in_git)

    send_blob(@repository, @blob, allow_caching: @project.public?)
  end

  def destroy
    @project.remove_avatar!
    @project.save

    redirect_to edit_project_path(@project, anchor: 'js-general-project-settings'), status: :found
  end
end
