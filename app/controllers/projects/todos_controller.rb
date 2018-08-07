class Projects::TodosController < Projects::ApplicationController
  include Gitlab::Utils::StrongMemoize
  include TodosActions

  before_action :authenticate_user!, only: [:create]

  private

  def issuable
    strong_memoize(:issuable) do
      case params[:issuable_type]
      when "issue"
        IssuesFinder.new(current_user, project_id: @project.id).find(params[:issuable_id])
      when "merge_request"
        MergeRequestsFinder.new(current_user, project_id: @project.id).find(params[:issuable_id])
      end
    end
  end
end
