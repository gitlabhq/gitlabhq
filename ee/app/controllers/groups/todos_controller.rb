class Groups::TodosController < Groups::ApplicationController
  include Gitlab::Utils::StrongMemoize
  include TodosActions

  before_action :authenticate_user!, only: [:create]

  private

  def issuable
    strong_memoize(:epic) do
      next if params[:issuable_type] != 'epic'

      @group.epics.find_by(id: params[:issuable_id])
    end
  end
end
