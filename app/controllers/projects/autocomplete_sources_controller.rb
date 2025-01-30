# frozen_string_literal: true

class Projects::AutocompleteSourcesController < Projects::ApplicationController
  include AutocompleteSources::ExpiresIn

  before_action :authorize_read_milestone!, only: :milestones
  before_action :authorize_read_crm_contact!, only: :contacts

  feature_category :team_planning, [:issues, :labels, :milestones, :commands, :contacts]
  feature_category :wiki, [:wikis]
  feature_category :code_review_workflow, [:merge_requests]
  feature_category :groups_and_projects, [:members]
  feature_category :source_code_management, [:snippets]

  urgency :low, [:merge_requests, :members]
  urgency :low, [:issues, :labels, :milestones, :commands, :contacts]

  def members
    render json: ::Projects::ParticipantsService.new(@project, current_user, params).execute(target)
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
    render json: autocomplete_service.commands(target)
  end

  def snippets
    render json: autocomplete_service.snippets
  end

  def contacts
    render json: autocomplete_service.contacts(target)
  end

  def wikis
    render json: autocomplete_service.wikis
  end

  private

  def autocomplete_service
    @autocomplete_service ||= ::Projects::AutocompleteService.new(@project, current_user, params)
  end

  def target
    # type_id is not required in general
    target_type = params.require(:type)

    # TODO https://gitlab.com/gitlab-org/gitlab/-/issues/388541
    # type_id is a misnomer. QuickActions::TargetService actually requires an iid.
    QuickActions::TargetService
      .new(container: project, current_user: current_user, params: params)
      .execute(target_type, params[:type_id])
  end

  def authorize_read_crm_contact!
    render_404 unless can?(current_user, :read_crm_contact, project.crm_group)
  end
end

Projects::AutocompleteSourcesController.prepend_mod_with('Projects::AutocompleteSourcesController')
