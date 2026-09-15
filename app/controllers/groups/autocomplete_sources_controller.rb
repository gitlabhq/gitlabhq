# frozen_string_literal: true

class Groups::AutocompleteSourcesController < Groups::ApplicationController
  include AutocompleteSources::ExpiresIn

  feature_category :groups_and_projects, [:members]
  feature_category :team_planning, [:issues, :labels, :milestones, :commands]
  feature_category :code_review_workflow, [:merge_requests]

  urgency :low, [:issues, :labels, :milestones, :commands, :merge_requests, :members]

  def members
    render json: ::Groups::ParticipantsService.new(@group, current_user, participants_params).execute(target)
  end

  def issues
    render json: issuable_serializer.represent(
      autocomplete_service.issues(
        confidential_only: permitted_params[:confidential_only],
        issue_types: permitted_params[:issue_types]
      ),
      parent: @group
    )
  end

  def merge_requests
    render json: issuable_serializer.represent(autocomplete_service.merge_requests, parent: @group)
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

  # ParticipantsService#mentioned_users reads :mentioned to keep already-@-mentioned
  # users in the payload, so it must be permitted alongside :search.
  def participants_params
    params.permit(:search, mentioned: [])
  end

  def permitted_params
    params.permit(:confidential_only, :issue_types, :type, :type_id)
  end
  strong_memoize_attr :permitted_params

  # Passed whole to AutocompleteService, so the key set here is the behaviour.
  def autocomplete_service_params
    params.permit(:search)
  end

  def autocomplete_service
    @autocomplete_service ||= ::Groups::AutocompleteService.new(@group, current_user, autocomplete_service_params)
  end

  def issuable_serializer
    ::Autocomplete::IssuableSerializer.new
  end

  def target
    # TODO https://gitlab.com/gitlab-org/gitlab/-/issues/388541
    # type_id is a misnomer. QuickActions::TargetService actually requires an iid.
    QuickActions::TargetService
      .new(container: @group, current_user: current_user)
      .execute(permitted_params[:type], permitted_params[:type_id])
  end
end

Groups::AutocompleteSourcesController.prepend_mod
