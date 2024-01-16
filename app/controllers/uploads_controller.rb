# frozen_string_literal: true

class UploadsController < ApplicationController
  include UploadsActions
  include WorkhorseRequest

  UnknownUploadModelError = Class.new(StandardError)

  MODEL_CLASSES = {
    "user" => User,
    "project" => Project,
    "note" => Note,
    "group" => Group,
    "appearance" => Appearance,
    "personal_snippet" => PersonalSnippet,
    "projects/topic" => Projects::Topic,
    'alert_management_metric_image' => ::AlertManagement::MetricImage,
    "achievements/achievement" => Achievements::Achievement,
    "organizations/organization_detail" => Organizations::OrganizationDetail,
    "abuse_report" => AbuseReport,
    nil => PersonalSnippet
  }.freeze

  rescue_from UnknownUploadModelError, with: :render_404

  skip_before_action :authenticate_user!
  skip_before_action :check_two_factor_requirement, only: [:show]
  before_action :upload_mount_satisfied?
  before_action :authorize_access!, only: [:show]
  before_action :authorize_create_access!, only: [:create, :authorize]
  before_action :verify_workhorse_api!, only: [:authorize]

  feature_category :groups_and_projects

  def self.model_classes
    MODEL_CLASSES
  end

  def uploader_class
    PersonalFileUploader
  end

  def find_model
    upload_model_class.find(params[:id])
  end

  def authorized?
    case model
    when Note
      can?(current_user, :read_project, model.project)
    when Snippet, ProjectSnippet
      can?(current_user, :read_snippet, model)
    when User
      # We validate the current user has enough (writing)
      # access to itself when a secret is given.
      # For instance, user avatars are readable by anyone,
      # while temporary, user snippet uploads are not.
      return false if !current_user && public_visibility_restricted?

      !secret? || can?(current_user, :update_user, model)
    when Appearance
      true
    when Projects::Topic
      true
    when ::AlertManagement::MetricImage
      can?(current_user, :read_alert_management_metric_image, model.alert)
    when ::Achievements::Achievement
      true
    when Organizations::OrganizationDetail
      can?(current_user, :read_organization, model.organization)
    else
      can?(current_user, "read_#{model.class.underscore}".to_sym, model)
    end
  end

  def authorize_access!
    render_unauthorized unless authorized?
  end

  def authorize_create_access!
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
    if current_user || workhorse_authorize_request?
      render_404
    else
      authenticate_user!
    end
  end

  def cache_settings
    case model
    when User, Appearance, Projects::Topic, Achievements::Achievement, Organizations::OrganizationDetail
      [5.minutes, { public: true, must_revalidate: false }]
    when Project, Group
      [5.minutes, { private: true, must_revalidate: true }]
    end
  end

  def secret?
    params[:secret].present?
  end

  def upload_model_class
    self.class.model_classes[params[:model]] || raise(UnknownUploadModelError)
  end

  def upload_model_class_has_mounts?
    upload_model_class < CarrierWave::Mount::Extension
  end

  def upload_mount_satisfied?
    return true unless upload_model_class_has_mounts?

    upload_model_class.uploader_options.has_key?(upload_mount)
  end
end

UploadsController.prepend_mod_with('UploadsController')
