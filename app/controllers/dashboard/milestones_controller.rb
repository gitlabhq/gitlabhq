class Dashboard::MilestonesController < Dashboard::ApplicationController
  include GlobalMilestones

  before_action :projects
  before_action :milestone, only: [:show]

  def index
    respond_to do |format|
      format.html do
        @milestones = Kaminari.paginate_array(milestones).page(params[:page])
      end
      format.json do
        render json: milestones
      end
    end
  end

  def show
  end
end
