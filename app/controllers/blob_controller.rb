# Controller for viewing a file's blame
class BlobController < ProjectResourceController
  include ExtractsPath

  # Authorize
  before_filter :authorize_read_project!
  before_filter :authorize_code_access!
  before_filter :require_non_empty_project

  before_filter :assign_ref_vars

  def show
    if @tree.is_blob?
      send_data(
        @tree.data,
        type: @tree.mime_type,
        disposition: 'inline',
        filename: @tree.name
      )
    else
      not_found!
    end
  end
end
