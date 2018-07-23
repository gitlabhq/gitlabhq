class InstanceStatistics::ApplicationController < ApplicationController
  before_action :authenticate_user!
  layout 'instance_statistics'

  def authenticate_user!
    render_404 unless can?(current_user, :read_instance_statistics)
  end
end
