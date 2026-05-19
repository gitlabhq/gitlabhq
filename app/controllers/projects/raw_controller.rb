# frozen_string_literal: true

# Controller for viewing a file's raw
class Projects::RawController < Projects::ApplicationController
  include ExtractsPath
  include SendsBlob
  include StaticObjectExternalStorage
  include HandlesGitalyErrors

  prepend_before_action(only: [:show]) { authenticate_sessionless_user!(:blob) }

  before_action :assign_ref_vars
  before_action :require_non_empty_project
  before_action :authorize_read_code!
  with_options only: [:show], unless: :external_storage_request? do
    before_action :check_show_blob_path_rate_limit!
    before_action :check_show_unauthenticated_rate_limit!
  end
  before_action :redirect_to_external_storage, only: :show, if: :static_objects_external_storage_enabled?

  feature_category :source_code_management

  def show
    @blob = @repository.blob_at(ref, @path, limit: Gitlab::Git::Blob::LFS_POINTER_MAX_SIZE)

    send_blob(@repository, @blob, inline: (params[:inline] != 'false'), allow_caching:
::Users::Anonymous.can?(:read_code, @project))
  end

  private

  # Override to render plain text instead of HTML template
  # since RawController serves raw file content, not HTML pages
  def handle_gitaly_error(exception)
    Gitlab::ErrorTracking.track_exception(exception)

    render plain: gitaly_unavailable_message, status: :service_unavailable
  end

  def ref
    @fully_qualified_ref || @ref
  end

  def check_show_blob_path_rate_limit!
    check_rate_limit!(:raw_blob, scope: [@project, @path]) do
      render plain: _('You cannot access the raw file. Please wait a minute.'), status: :too_many_requests
    end
  end

  def check_show_unauthenticated_rate_limit!
    return if current_user

    check_rate_limit!(:raw_blob_unauthenticated, scope: @project) do
      message = _('You cannot access the raw file. Please wait a minute or authenticate and try again.')
      render plain: message, status: :too_many_requests
    end
  end
end

Projects::RawController.prepend_mod
