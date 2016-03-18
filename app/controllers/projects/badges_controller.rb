class Projects::BadgesController < Projects::ApplicationController
  before_action :no_cache_headers

  def build
    respond_to do |format|
      format.html { render_404 }
      format.svg do
        image = Ci::ImageForBuildService.new.execute(project, ref: params[:ref])
        send_file(image.path, filename: image.name, disposition: 'inline', type: 'image/svg+xml')
      end
    end
  end
end
