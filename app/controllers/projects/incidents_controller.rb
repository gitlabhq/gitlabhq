# frozen_string_literal: true

class Projects::IncidentsController < Projects::ApplicationController
  include IssuableActions
  include Gitlab::Utils::StrongMemoize

  before_action :authorize_read_issue!
  before_action :check_feature_flag, only: [:show]
  before_action :load_incident, only: [:show]

  before_action do
    push_frontend_feature_flag(:issues_incident_details, @project)
  end

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

  def check_feature_flag
    render_404 unless Feature.enabled?(:issues_incident_details, @project)
  end
end
