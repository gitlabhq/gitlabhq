# frozen_string_literal: true

class WebIdeTerminal
  include ::Gitlab::Routing

  attr_reader :build, :project

  delegate :id, :status, to: :build

  def initialize(build)
    @build = build
    @project = build.project
  end

  def show_path
    web_ide_terminal_route_generator(:show)
  end

  def retry_path
    web_ide_terminal_route_generator(:retry)
  end

  def cancel_path
    web_ide_terminal_route_generator(:cancel)
  end

  def terminal_path
    terminal_project_job_path(project, build, format: :ws)
  end

  def proxy_websocket_path
    proxy_project_job_path(project, build, format: :ws)
  end

  def services
    build.services.map(&:alias).compact + Array(build.image&.alias)
  end

  private

  def web_ide_terminal_route_generator(action, options = {})
    options.reverse_merge!(
      action: action,
      controller: 'projects/web_ide_terminals',
      namespace_id: project.namespace.to_param,
      project_id: project.to_param,
      id: build.id,
      only_path: true
    )

    url_for(options)
  end
end
