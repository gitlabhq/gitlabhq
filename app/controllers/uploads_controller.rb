class UploadsController < ApplicationController
  include UploadsActions

  skip_before_action :authenticate_user!
  before_action :find_model
  before_action :authorize_access!, only: [:show]
  before_action :authorize_create_access!, only: [:create]

  private

  def find_model
    return render_404 unless upload_model && upload_mount

    @model = upload_model.find(params[:id])
  end

  def authorize_access!
    authorized =
      case model
      when Note
        can?(current_user, :read_project, model.project)
      when User
        true
      else
        permission = "read_#{model.class.to_s.underscore}".to_sym

        can?(current_user, permission, model)
      end

    render_unauthorized unless authorized
  end

  def authorize_create_access!
    # for now we support only personal snippets comments
    authorized = can?(current_user, :comment_personal_snippet, model)

    render_unauthorized unless authorized
  end

  def render_unauthorized
    if current_user
      render_404
    else
      authenticate_user!
    end
  end

  def upload_model
    upload_models = {
      "user"    => User,
      "project" => Project,
      "note"    => Note,
      "group"   => Group,
      "appearance" => Appearance,
      "personal_snippet" => PersonalSnippet
    }

    upload_models[params[:model]]
  end

  def upload_mount
    return true unless params[:mounted_as]

    upload_mounts = %w(avatar attachment file logo header_logo)

    if upload_mounts.include?(params[:mounted_as])
      params[:mounted_as]
    end
  end

  def uploader
    return @uploader if defined?(@uploader)

    if model.is_a?(PersonalSnippet)
      @uploader = PersonalFileUploader.new(model, params[:secret])

      @uploader.retrieve_from_store!(params[:filename])
    else
      @uploader = @model.send(upload_mount)

      redirect_to @uploader.url unless @uploader.local_storage?
    end

    @uploader
  end

  def uploader_class
    PersonalFileUploader
  end

  def model
    @model ||= find_model
  end
end
