# frozen_string_literal: true

# Controller for viewing a file's raw
class Projects::RawController < Projects::ApplicationController
  include ExtractsPath
  include SendsBlob
  include StaticObjectExternalStorage

  prepend_before_action(only: [:show]) { authenticate_sessionless_user!(:blob) }

  before_action :assign_ref_vars
  before_action :require_non_empty_project
  before_action :authorize_read_code!
  before_action :check_show_rate_limit!, only: [:show], unless: :external_storage_request?
  before_action :redirect_to_external_storage, only: :show, if: :static_objects_external_storage_enabled?

  feature_category :source_code_management

  def show
    @blob = @repository.blob_at(@ref, @path, limit: Gitlab::Git::Blob::LFS_POINTER_MAX_SIZE)

    send_blob(@repository, @blob, inline: (params[:inline] != 'false'), allow_caching:
::Users::Anonymous.can?(:read_code, @project))
  end

  private

  def check_show_rate_limit!
    check_rate_limit!(:raw_blob, scope: [@project, @path]) do
      render plain: _('You cannot access the raw file. Please wait a minute.'), status: :too_many_requests
    end
  end
end

Projects::RawController.prepend_mod
