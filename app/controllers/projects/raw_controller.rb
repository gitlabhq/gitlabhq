# Controller for viewing a file's raw
class Projects::RawController < Projects::ApplicationController
  include ExtractsPath

  before_action :require_non_empty_project
  before_action :assign_ref_vars
  before_action :authorize_download_code!

  def show
    @blob = @repository.blob_at(@commit.id, @path)

    if @blob
      type = get_blob_type

      headers['X-Content-Type-Options'] = 'nosniff'

      send_data(
        @blob.data,
        type: type,
        disposition: 'inline'
      )
    else
      render_404
    end
  end

  private

  def get_blob_type
    if @blob.text?
      'text/plain; charset=utf-8'
    elsif @blob.image?
      @blob.content_type
    else
      'application/octet-stream'
    end
  end
end
