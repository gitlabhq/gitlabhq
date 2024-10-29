# frozen_string_literal: true

class Groups::AutocompleteSourcesController < Groups::ApplicationController
  include AutocompleteSources::ExpiresIn

  feature_category :groups_and_projects, [:members]
  feature_category :team_planning, [:issues, :labels, :milestones, :commands]
  feature_category :code_review_workflow, [:merge_requests]

  urgency :low, [:issues, :labels, :milestones, :commands, :merge_requests, :members]

  def members
    render json: ::Groups::ParticipantsService.new(@group, current_user, params).execute(target)
  end

  def issues
    render json: issuable_serializer.represent(
      autocomplete_service.issues(confidential_only: params[:confidential_only], issue_types: params[:issue_types]),
      parent_group: @group
    )
  end

  def merge_requests
    render json: issuable_serializer.represent(autocomplete_service.merge_requests, parent_group: @group)
  end

  def labels
    render json: autocomplete_service.labels_as_hash(target)
  end

  def commands
    render json: autocomplete_service.commands(target)
  end

  def milestones
    render json: autocomplete_service.milestones
  end

  private

  def autocomplete_service
    @autocomplete_service ||= ::Groups::AutocompleteService.new(@group, current_user, params)
  end

  def issuable_serializer
    GroupIssuableAutocompleteSerializer.new
  end

  def target
    # TODO https://gitlab.com/gitlab-org/gitlab/-/issues/388541
    # type_id is a misnomer. QuickActions::TargetService actually requires an iid.
    QuickActions::TargetService
      .new(container: @group, current_user: current_user)
      .execute(params[:type], params[:type_id])
  end
end

Groups::AutocompleteSourcesController.prepend_mod
