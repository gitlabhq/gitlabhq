class Projects::BadgesController < Projects::ApplicationController
  before_action :set_no_cache

  def build
    respond_to do |format|
      format.html { render_404 }
      format.svg do
        image = Ci::ImageForBuildService.new.execute(project, ref: params[:ref])
        send_file(image.path, filename: image.name, disposition: 'inline', type: 'image/svg+xml')
      end
    end
  end

  private

  def set_no_cache
    expires_now

    # Add some deprecated headers for older agents
    #
    response.headers['Pragma'] = 'no-cache'
    response.headers['Expires'] = 'Fri, 01 Jan 1990 00:00:00 GMT'
  end
end
