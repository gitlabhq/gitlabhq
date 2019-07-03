# frozen_string_literal: true

class UploadsController < ApplicationController
  include UploadsActions

  UnknownUploadModelError = Class.new(StandardError)

  MODEL_CLASSES = {
    "user"             => User,
    "project"          => Project,
    "note"             => Note,
    "group"            => Group,
    "appearance"       => Appearance,
    "personal_snippet" => PersonalSnippet,
    nil                => PersonalSnippet
  }.freeze

  rescue_from UnknownUploadModelError, with: :render_404

  skip_before_action :authenticate_user!
  before_action :upload_mount_satisfied?
  before_action :find_model
  before_action :authorize_access!, only: [:show]
  before_action :authorize_create_access!, only: [:create]

  def uploader_class
    PersonalFileUploader
  end

  def find_model
    return unless params[:id]

    upload_model_class.find(params[:id])
  end

  def authorize_access!
    return unless model

    authorized =
      case model
      when Note
        can?(current_user, :read_project, model.project)
      when User
        # We validate the current user has enough (writing)
        # access to itself when a secret is given.
        # For instance, user avatars are readable by anyone,
        # while temporary, user snippet uploads are not.
        !secret? || can?(current_user, :update_user, model)
      when Appearance
        true
      else
        permission = "read_#{model.class.underscore}".to_sym

        can?(current_user, permission, model)
      end

    render_unauthorized unless authorized
  end

  def authorize_create_access!
    return unless model

    authorized =
      case model
      when User
        can?(current_user, :update_user, model)
      else
        can?(current_user, :create_note, model)
      end

    render_unauthorized unless authorized
  end

  def render_unauthorized
    if current_user
      render_404
    else
      authenticate_user!
    end
  end

  def cache_publicly?
    User === model || Appearance === model
  end

  def secret?
    params[:secret].present?
  end

  def upload_model_class
    MODEL_CLASSES[params[:model]] || raise(UnknownUploadModelError)
  end

  def upload_model_class_has_mounts?
    upload_model_class < CarrierWave::Mount::Extension
  end

  def upload_mount_satisfied?
    return true unless upload_model_class_has_mounts?

    upload_model_class.uploader_options.has_key?(upload_mount)
  end
end
