class Projects::AutocompleteSourcesController < Projects::ApplicationController
  before_action :load_autocomplete_service, except: [:emojis, :members]

  def emojis
    render json: Gitlab::AwardEmoji.urls
  end

  def members
    render json: ::Projects::ParticipantsService.new(@project, current_user).execute(noteable)
  end

  def issues
    render json: @autocomplete_service.issues
  end

  def merge_requests
    render json: @autocomplete_service.merge_requests
  end

  def labels
    render json: @autocomplete_service.labels
  end

  def milestones
    render json: @autocomplete_service.milestones
  end

  def commands
    render json: @autocomplete_service.commands(noteable, params[:type])
  end

  private

  def load_autocomplete_service
    @autocomplete_service = ::Projects::AutocompleteService.new(@project, current_user)
  end

  def noteable
    case params[:type]
    when 'Issue'
      IssuesFinder.new(current_user, project_id: @project.id).execute.find_by(iid: params[:type_id])
    when 'MergeRequest'
      MergeRequestsFinder.new(current_user, project_id: @project.id).execute.find_by(iid: params[:type_id])
    when 'Commit'
      @project.commit(params[:type_id])
    end
  end
end
