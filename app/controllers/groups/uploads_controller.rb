# frozen_string_literal: true

class Groups::UploadsController < Groups::ApplicationController
  include UploadsActions
  include WorkhorseRequest

  skip_before_action :group, if: -> { action_name == 'show' && embeddable? }

  # TODO: Remove this skip and implement step-up auth enforcement for uploads
  # See: https://gitlab.com/gitlab-org/gitlab/-/issues/578693
  # This skip_before_action is temporary to avoid breaking uploads while we add
  # comprehensive test coverage and proper enforcement in a follow-up MR.
  skip_before_action :enforce_step_up_auth_for_namespace

  before_action :authorize_upload_file!, only: [:create, :authorize]
  before_action :verify_workhorse_api!, only: [:authorize]
  before_action :disallow_new_uploads!, only: :show

  feature_category :portfolio_management

  private

  # Starting with this version, #show is handled by Banzai::UploadsController#show
  def disallow_new_uploads!
    render_404 if upload_version_at_least?(ID_BASED_UPLOAD_PATH_VERSION)
  end

  def upload_model_class
    Group
  end

  def uploader_class
    NamespaceFileUploader
  end

  def find_model
    return @group if @group

    group_id = params[:group_id]

    Group.find_by_full_path(group_id)
  end

  def authorize_upload_file!
    render_404 unless can?(current_user, :upload_file, group)
  end
end
