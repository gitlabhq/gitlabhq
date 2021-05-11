# frozen_string_literal: true

class Projects::AutocompleteSourcesController < Projects::ApplicationController
  before_action :authorize_read_milestone!, only: :milestones

  feature_category :issue_tracking, [:issues, :labels, :milestones, :commands]
  feature_category :code_review, [:merge_requests]
  feature_category :users, [:members]
  feature_category :snippets, [:snippets]

  def members
    render json: ::Projects::ParticipantsService.new(@project, current_user).execute(target)
  end

  def issues
    render json: autocomplete_service.issues
  end

  def merge_requests
    render json: autocomplete_service.merge_requests
  end

  def labels
    render json: autocomplete_service.labels_as_hash(target)
  end

  def milestones
    render json: autocomplete_service.milestones
  end

  def commands
    render json: autocomplete_service.commands(target, params[:type])
  end

  def snippets
    render json: autocomplete_service.snippets
  end

  private

  def autocomplete_service
    @autocomplete_service ||= ::Projects::AutocompleteService.new(@project, current_user, params)
  end

  def target
    QuickActions::TargetService
      .new(project, current_user)
      .execute(params[:type], params[:type_id])
  end
end

Projects::AutocompleteSourcesController.prepend_mod_with('Projects::AutocompleteSourcesController')
