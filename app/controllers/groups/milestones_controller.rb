class Groups::MilestonesController < ApplicationController
  layout 'group'

  def index
    @group = Group.find_by(path: params[:group_id])
  end
end
