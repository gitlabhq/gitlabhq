class Dashboard::MilestonesController < Dashboard::ApplicationController
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

  private

  def milestones
    @milestones = GlobalMilestone.build_collection(@projects, params)
  end

  def milestone
    @milestone = GlobalMilestone.build(@projects, params[:title])
    render_404 unless @milestone
  end
end
