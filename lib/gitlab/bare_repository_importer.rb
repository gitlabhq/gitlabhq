module Gitlab
  class BareRepositoryImporter
    include Gitlab::ShellAdapter

    NoAdminError = Class.new(StandardError)

    def self.execute(import_path)
      import_path << '/' unless import_path.ends_with?('/')
      repos_to_import = Dir.glob(import_path + '/**/*.git')

      repos_to_import.each do |repo_path|
        project_repo_path = Gitlab::ProjectRepoPath.new(import_path, repo_path)

        if project_repo_path.wiki?
          log " * Skipping wiki repo"

          next
        end

        log "Processing #{repo_path}".color(:yellow)

        new(project_repo_path).create_project_if_needed
      end
    end

    attr_reader :storage_name, :user, :project_name
    delegate :log, to: :class

    def initialize(project_repo_path)
      unless @user = User.admins.order_id_asc.first
        raise NoAdminError.new('No admin user found to import repositories')
      end

      @project_repo_path = project_repo_path
      @project_name = project_repo_path.project_name
    end

    def create_project_if_needed
      if project = Project.find_by_full_path(@project_repo_path.project_full_path)
        log " * #{project.name} (#{@project_repo_path.project_full_path}) exists"

        return project
      end

      create_project
    end

    private

    def create_project
      group = find_or_create_groups

      project = Projects::CreateService.new(user,
                                            name: project_name,
                                            path: project_name,
                                            skip_disk_validation: true,
                                            import_type: 'gitlab_project',
                                            namespace_id: group&.id).execute

      if project.persisted? && import_repo(project)

        log " * Created #{project.name} (#{@project_repo_path.project_full_path})".color(:green)

        ProjectCacheWorker.perform_async(project.id)
      else
        log " * Failed trying to create #{project.name} (#{@project_repo_path.project_full_path})".color(:red)
        log "   Errors: #{project.errors.messages}".color(:red)
      end

      project
    end

    def import_repo(project)
      gitlab_shell.import_repository(project.repository_storage_path, project.disk_path, @project_repo_path.repo_path)
    end

    def find_or_create_groups
      group_path = @project_repo_path.group_path

      return nil unless group_path.present?

      log " * Using namespace: #{group_path}"

      Groups::NestedCreateService.new(user, group_path: group_path).execute
    end

    # This is called from within a rake task only used by Admins, so allow writing
    # to STDOUT
    #
    # rubocop:disable Rails/Output
    def self.log(message)
      puts message
    end
    # rubocop:enable Rails/Output
  end
end
