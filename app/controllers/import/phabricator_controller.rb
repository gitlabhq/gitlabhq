# frozen_string_literal: true

class Import::PhabricatorController < Import::BaseController
  include ImportHelper

  before_action :verify_import_enabled

  def new
  end

  def create
    @project = Gitlab::PhabricatorImport::ProjectCreator
                 .new(current_user, import_params).execute

    if @project&.persisted?
      redirect_to @project
    else
      @name = params[:name]
      @path = params[:path]
      @errors = @project&.errors&.full_messages || [_("Invalid import params")]

      render :new
    end
  end

  def verify_import_enabled
    render_404 unless phabricator_import_enabled?
  end

  private

  def import_params
    params.permit(:path, :phabricator_server_url, :api_token, :name, :namespace_id)
  end
end
