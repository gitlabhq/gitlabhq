# Controller for viewing a file's raw
class Projects::RawController < Projects::ApplicationController
  include ExtractsPath

  # Authorize
  before_filter :authorize_download_code!
  before_filter :require_non_empty_project

  def show
    @blob = @repository.blob_at(@commit.id, @path)

    if @blob
      type = get_blob_type

      headers['X-Content-Type-Options'] = 'nosniff'

      send_data(
        @blob.data,
        type: type,
        disposition: 'inline',
        filename: @blob.name
      )
    else
      not_found!
    end
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

