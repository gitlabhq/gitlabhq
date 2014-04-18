class Projects::WallsController < Projects::ApplicationController
  before_filter :module_enabled

  respond_to :js, :html

  def show
    @note = @project.notes.new

    respond_to do |format|
      format.html
    end
  end

  protected

  def module_enabled
    return render_404 unless @project.wall_enabled
  end
end

