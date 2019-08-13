# frozen_string_literal: true

# Controller for viewing a file's raw
class Projects::RawController < Projects::ApplicationController
  include ExtractsPath
  include SendsBlob

  before_action :require_non_empty_project
  before_action :assign_ref_vars
  before_action :authorize_download_code!
  before_action :show_rate_limit, only: [:show]

  def show
    @blob = @repository.blob_at(@commit.id, @path)

    send_blob(@repository, @blob, inline: (params[:inline] != 'false'))
  end

  private

  def show_rate_limit
    limiter = ::Gitlab::ActionRateLimiter.new(action: :show_raw_controller)

    return unless limiter.throttled?([@project, @commit, @path], raw_blob_request_limit)

    limiter.log_request(request, :raw_blob_request_limit, current_user)

    flash[:alert] = _('You cannot access the raw file. Please wait a minute.')
    redirect_to project_blob_path(@project, File.join(@ref, @path)), status: :too_many_requests
  end

  def raw_blob_request_limit
    Gitlab::CurrentSettings
      .current_application_settings
      .raw_blob_request_limit
  end
end
