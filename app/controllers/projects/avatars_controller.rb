# frozen_string_literal: true

class Projects::AvatarsController < Projects::ApplicationController
  include SendsBlob
  include HandlesGitalyErrors

  before_action :authorize_admin_project!, only: [:destroy]

  feature_category :groups_and_projects

  urgency :low, [:show]

  def show
    @blob = @repository.blob_at_branch(@repository.root_ref, @project.avatar_in_git)

    send_blob(@repository, @blob, allow_caching: @project.public?)
  end

  def destroy
    @project.remove_avatar!
    @project.save

    redirect_to edit_project_path(@project, anchor: 'js-general-project-settings'), status: :found
  end

  private

  # Override to render plain text instead of HTML template
  # since AvatarsController serves binary content, not HTML pages.
  #
  def handle_gitaly_error(exception)
    Gitlab::ErrorTracking.track_exception(exception)

    render plain: gitaly_unavailable_message, status: :service_unavailable
  end
end
