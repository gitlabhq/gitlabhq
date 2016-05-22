#encoding: utf-8
class Projects::ServicesController < Projects::ApplicationController
  ALLOWED_PARAMS = [:title, :token, :type, :active, :api_key, :api_url, :api_version, :subdomain,
                    :room, :recipients, :project_url, :webhook,
                    :user_key, :device, :priority, :sound, :bamboo_url, :username, :password,
                    :build_key, :server, :teamcity_url, :drone_url, :build_type,
                    :description, :issues_url, :new_issue_url, :restrict_to_branch, :channel,
                    :colorize_messages, :channels,
                    :push_events, :issues_events, :merge_requests_events, :tag_push_events,
                    :note_events, :build_events, :wiki_page_events,
                    :notify_only_broken_builds, :add_pusher,
                    :send_from_committer_email, :disable_diffs, :external_wiki_url,
                    :notify, :color,
                    :server_host, :server_port, :default_irc_uri, :enable_ssl_verification,
                    :jira_issue_transition_id]

  # Parameters to ignore if no value is specified
  FILTER_BLANK_PARAMS = [:password]

  # Authorize
  before_action :authorize_admin_project!
  before_action :service, only: [:edit, :update, :test]

  respond_to :html

  layout "project_settings"

  def index
    @project.build_missing_services
    @services = @project.services.visible.reload
  end

  def edit
  end

  def update
    if @service.update_attributes(service_params)
      redirect_to(
        edit_namespace_project_service_path(@project.namespace, @project,
                                            @service.to_param, notice:
                                            '已更新成功。')
      )
    else
      render 'edit'
    end
  end

  def test
    data = Gitlab::PushDataBuilder.build_sample(project, current_user)
    outcome = @service.test(data)
    if outcome[:success]
      message = { notice: '已发送请求到提供的链接' }
    else
      error_message = "已发送请求到提供的链接，但收到一个错误回应"
      error_message << ": #{outcome[:result]}" if outcome[:result].present?
      message = { alert: error_message }
    end

    redirect_back_or_default(options: message)
  end

  private

  def service
    @service ||= @project.services.find { |service| service.to_param == params[:id] }
  end

  def service_params
    service_params = params.require(:service).permit(ALLOWED_PARAMS)
    FILTER_BLANK_PARAMS.each do |param|
      service_params.delete(param) if service_params[param].blank?
    end
    service_params
  end
end
