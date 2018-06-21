class Groups::TodosController < Groups::ApplicationController
  include TodosActions

  before_action :authenticate_user!, only: [:create]

  private

  def issuable
    strong_memoize(:epic) do
      case params[:issuable_type]
      when "epic"
        @group.epics.find_by(id: params[:issuable_id])
      end
    end
  end
end
