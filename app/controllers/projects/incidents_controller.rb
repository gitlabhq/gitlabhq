# frozen_string_literal: true

class Projects::IncidentsController < Projects::ApplicationController
  include IssuableActions
  include Gitlab::Utils::StrongMemoize

  before_action :authorize_read_issue!
  before_action :load_incident, only: [:show]

  feature_category :incident_management

  def index
  end

  private

  def incident
    strong_memoize(:incident) do
      incident_finder
        .execute
        .inc_relations_for_view
        .iid_in(params[:id])
        .without_order
        .first
    end
  end

  def load_incident
    @issue = incident # needed by rendered view
    return render_404 unless can?(current_user, :read_issue, incident)

    @noteable = incident
    @note = incident.project.notes.new(noteable: issuable)
  end

  alias_method :issuable, :incident

  def incident_finder
    IssuesFinder.new(current_user, project_id: @project.id, issue_types: :incident)
  end

  def serializer
    IssueSerializer.new(current_user: current_user, project: incident.project)
  end
end
