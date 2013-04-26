class ServicesController < ProjectResourceController
  # Authorize
  before_filter :authorize_admin_project!

  respond_to :html

  def index
    @active_project_services = @project.active_project_services
    @inactive_project_services = @project.inactive_project_services
  end

  def edit
    @project_service = @project.project_service(params)
    @service = @project_service.service
  end

  def update
    @project_service = @project.project_service(params)
    @service = @project_service.service

    if @project_service.update_attributes(params[:service])
      redirect_to edit_project_service_path(@project, params[:id])
    else
      render 'edit'
    end
  end

  def test
    payload = GitPushService.new.sample_data(project, current_user)

    # The following code is just here for testing purposes, should be moved elsewhere
    payload[:commits].each_with_index do |commit, i|
      payload[:commits][i][:distinct] = true
    end
    payload[:pusher] = {:name=>current_user.name}
    payload[:ref] = 'refs/heads/master' if payload[:ref] == 'refs/heads/'
    project_service = @project.project_service(params)
    service = project_service.service

    begin
      s = service.new(:push, project_service.data.with_indifferent_access, payload.with_indifferent_access)
      if s.respond_to? :receive_event
        s.receive_event
      elsif s.respond_to? :receive_push
        s.receive_push
      end
      flash[:notice] = 'Test succeeded'
    rescue Exception => e
      flash[:alert] = e.to_s
    end

    
    redirect_to :back
  end
end
