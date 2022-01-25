# frozen_string_literal: true

class Projects::AutocompleteSourcesController < Projects::ApplicationController
  before_action :authorize_read_milestone!, only: :milestones
  before_action :authorize_read_crm_contact!, only: :contacts

  feature_category :team_planning, [:issues, :labels, :milestones, :commands, :contacts]
  feature_category :code_review, [:merge_requests]
  feature_category :users, [:members]
  feature_category :snippets, [:snippets]

  urgency :low, [:merge_requests]

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

  def contacts
    render json: autocomplete_service.contacts
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

  def authorize_read_crm_contact!
    render_404 unless can?(current_user, :read_crm_contact, project.root_ancestor)
  end
end

Projects::AutocompleteSourcesController.prepend_mod_with('Projects::AutocompleteSourcesController')
