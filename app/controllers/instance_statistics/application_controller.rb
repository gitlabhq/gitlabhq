class InstanceStatistics::ApplicationController < ApplicationController
  before_action :authenticate_user!
  layout 'instance_statistics'

  def index
    redirect_to instance_statistics_conversations_development_index_index_path
  end

  def authenticate_user!
    render_404 unless current_user.admin?
  end
end
