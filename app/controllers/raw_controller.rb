# Controller for viewing a file's raw
class RawController < ProjectResourceController
  include ExtractsPath

  # Authorize
  before_filter :authorize_read_project!
  before_filter :authorize_code_access!
  before_filter :require_non_empty_project

  def show
    @blob = Gitlab::Git::Blob.new(@repository, @commit.id, @ref, @path)

    if @blob.exists?
      send_data(
        @blob.data,
        type: @blob.mime_type,
        disposition: 'inline',
        filename: @blob.name
      )
    else
      not_found!
    end
  end
end

