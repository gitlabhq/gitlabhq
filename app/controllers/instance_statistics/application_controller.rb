class InstanceStatistics::ApplicationController < ApplicationController
  before_action :authorize_read_instance_statistics!
  layout 'instance_statistics'

  def authorize_read_instance_statistics!
    render_404 unless can?(current_user, :read_instance_statistics)
  end
end
