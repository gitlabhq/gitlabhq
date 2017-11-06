class Groups::EpicsController < Groups::ApplicationController
  include IssuableActions

  before_action :epic
  before_action :authorize_update_issuable!, only: :update

  skip_before_action :labels

  private

  def epic
    @issuable = @epic ||= @group.epics.find_by(iid: params[:id])

    return render_404 unless can?(current_user, :read_epic, @epic)

    @epic
  end
  alias_method :issuable, :epic

  def epic_params
    params.require(:epic).permit(*epic_params_attributes)
  end

  def epic_params_attributes
    %i[
      title
      description
      start_date
      end_date
    ]
  end

  def serializer
    EpicSerializer.new(current_user: current_user)
  end

  def update_service
    Epics::UpdateService.new(nil, current_user, epic_params)
  end

  def show_view
    'groups/ee/epics/show'
  end
end
