module GlobalMilestones
  extend ActiveSupport::Concern

  def milestones
    epoch = DateTime.parse('1970-01-01')
    @milestones = MilestonesFinder.new.execute(@projects, params)
    @milestones = GlobalMilestone.build_collection(@milestones)
    @milestones = @milestones.sort_by { |x| x.due_date.nil? ? epoch : x.due_date }
    @milestones = Kaminari.paginate_array(@milestones).page(params[:page]).per(ApplicationController::PER_PAGE)
  end

  def milestone
    milestones = Milestone.of_projects(@projects).where(title: params[:title])

    if milestones.present?
      @milestone = GlobalMilestone.new(params[:title], milestones)
    else
      render_404
    end
  end
end
