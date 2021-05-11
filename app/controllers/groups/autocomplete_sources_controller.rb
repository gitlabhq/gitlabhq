# frozen_string_literal: true

class Groups::AutocompleteSourcesController < Groups::ApplicationController
  feature_category :subgroups, [:members]
  feature_category :issue_tracking, [:issues, :labels, :milestones, :commands]
  feature_category :code_review, [:merge_requests]

  def members
    render json: ::Groups::ParticipantsService.new(@group, current_user).execute(target)
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

  # rubocop: disable CodeReuse/ActiveRecord
  def target
    QuickActions::TargetService
      .new(nil, current_user, group: @group)
      .execute(params[:type], params[:type_id])
  end
  # rubocop: enable CodeReuse/ActiveRecord
end

Groups::AutocompleteSourcesController.prepend_mod
