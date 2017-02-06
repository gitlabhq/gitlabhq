module Geo
  class RepositoryBackfillService
    attr_reader :project, :geo_node

    def initialize(project, geo_node)
      @project = project
      @geo_node = geo_node
    end

    def execute
      geo_node.system_hook.execute(hook_data, 'system_hooks')
    end

    private

    def hook_data
      {
        event_name: 'repository_update',
        project_id: project.id,
        project: project.hook_attrs,
        remote_url: project.ssh_url_to_repo
      }
    end
  end
end
