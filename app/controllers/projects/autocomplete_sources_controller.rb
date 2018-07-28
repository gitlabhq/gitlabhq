class Projects::AutocompleteSourcesController < Projects::ApplicationController
  before_action :load_autocomplete_service

  def members
    render json: ::Projects::ParticipantsService.new(@project, current_user).execute(target)
  end

  def issues
    render json: @autocomplete_service.issues
  end

  def merge_requests
    render json: @autocomplete_service.merge_requests
  end

  def labels
    render json: @autocomplete_service.labels_as_hash(target)
  end

  def milestones
    render json: @autocomplete_service.milestones
  end

  def commands
    render json: @autocomplete_service.commands(target, params[:type])
  end

  private

  def load_autocomplete_service
    @autocomplete_service = ::Projects::AutocompleteService.new(@project, current_user)
  end

  def target
    @autocomplete_service.target(params[:type], params[:type_id])
  end
end
