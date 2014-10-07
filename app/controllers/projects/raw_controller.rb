# Controller for viewing a file's raw
class Projects::RawController < Projects::ApplicationController
  include ExtractsPath

  # Authorize
  before_filter :authorize_read_project!
  before_filter :authorize_code_access!
  before_filter :require_non_empty_project
  before_filter :blob

  def show
    type = get_blob_type

    headers['X-Content-Type-Options'] = 'nosniff'

    send_data(
      @blob.data,
      type: type,
      disposition: 'inline',
      filename: @blob.name
    )
  end

  private

  def get_blob_type
    if @blob.text?
      'text/plain; charset=utf-8'
    else
      'application/octet-stream'
    end
  end
end

