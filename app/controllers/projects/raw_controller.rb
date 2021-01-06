# frozen_string_literal: true

# Controller for viewing a file's raw
class Projects::RawController < Projects::ApplicationController
  include ExtractsPath
  include SendsBlob
  include StaticObjectExternalStorage

  skip_before_action :default_cache_headers, only: :show

  prepend_before_action(only: [:show]) { authenticate_sessionless_user!(:blob) }

  before_action :set_ref_and_path
  before_action :require_non_empty_project
  before_action :authorize_download_code!
  before_action :show_rate_limit, only: [:show], unless: :external_storage_request?
  before_action :redirect_to_external_storage, only: :show, if: :static_objects_external_storage_enabled?

  feature_category :source_code_management

  def show
    @blob = @repository.blob_at(@ref, @path)

    send_blob(@repository, @blob, inline: (params[:inline] != 'false'), allow_caching: Guest.can?(:download_code, @project))
  end

  private

  def set_ref_and_path
    # This bypasses assign_ref_vars to avoid a Gitaly FindCommit lookup.
    # We don't need to find the commit to either rate limit or send the
    # blob.
    @ref, @path = extract_ref(get_id)
  end

  def show_rate_limit
    if rate_limiter.throttled?(:show_raw_controller, scope: [@project, @path], threshold: raw_blob_request_limit)
      rate_limiter.log_request(request, :raw_blob_request_limit, current_user)

      render plain: _('You cannot access the raw file. Please wait a minute.'), status: :too_many_requests
    end
  end

  def rate_limiter
    ::Gitlab::ApplicationRateLimiter
  end

  def raw_blob_request_limit
    Gitlab::CurrentSettings
      .current_application_settings
      .raw_blob_request_limit
  end
end
