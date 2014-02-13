# Controller for viewing a file's raw
class Projects::RawController < Projects::ApplicationController
  include ExtractsPath

  # Authorize
  before_filter :authorize_read_project!
  before_filter :authorize_code_access!
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
    if @blob.mime_type =~ /html|javascript/
      'text/plain; charset=utf-8'
    elsif @blob.name =~ /(?:msi|exe|rar|r0\d|7z|7zip|zip)$/
      'application/octet-stream'
    else
      @blob.mime_type
    end
  end
end

