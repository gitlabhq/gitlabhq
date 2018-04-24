class Groups::AutocompleteSourcesController < Groups::ApplicationController
  def members
    render json: ::Groups::ParticipantsService.new(@group, current_user).execute(target)
  end

  private

  def target
    case params[:type]&.downcase
    when 'epic'
      EpicsFinder.new(current_user, group_id: @group.id).find_by(iid: params[:type_id])
    end
  end
end
