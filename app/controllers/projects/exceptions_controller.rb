class Projects::ExceptionsController < Projects::ApplicationController
  before_action :module_enabled
  before_action :exception, only: :show

  # Allow read any exception
  # before_action :authorize_read_exception!

  respond_to :html

  def index
    @exceptions = @project.exceptions.page(params[:page]).per(PER_PAGE)

    respond_to do |format|
      format.html
      format.atom { render layout: false }
      format.json do
        render json: {
          html: view_to_html_string("projects/exceptions/_exceptions")
        }
      end
    end
  end

  def setup
  end

  def show
    respond_with(@exception)
  end

  protected

  def exception
    @exception ||= begin
                 @project.exceptions.find(params[:id])
               rescue ActiveRecord::RecordNotFound
                 redirect_old
               end
  end

  def module_enabled
    return render_404 unless @project.exceptions_enabled
  end

end