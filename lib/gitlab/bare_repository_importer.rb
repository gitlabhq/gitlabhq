module Gitlab
  class BareRepositoryImporter
    NoAdminError = Class.new(StandardError)

    def self.execute
      Gitlab.config.repositories.storages.each do |storage_name, repository_storage|
        git_base_path = repository_storage['path']
        repos_to_import = Dir.glob(git_base_path + '/**/*.git')

        repos_to_import.each do |repo_path|
          if repo_path.end_with?('.wiki.git')
            log " * Skipping wiki repo"
            next
          end

          log "Processing #{repo_path}".color(:yellow)

          repo_relative_path = repo_path[repository_storage['path'].length..-1]
                                 .sub(/^\//, '') # Remove leading `/`
                                 .sub(/\.git$/, '') # Remove `.git` at the end
          new(storage_name, repo_relative_path).create_project_if_needed
        end
      end
    end

    attr_reader :storage_name, :full_path, :group_path, :project_path, :user
    delegate :log, to: :class

    def initialize(storage_name, repo_path)
      @storage_name = storage_name
      @full_path = repo_path

      unless @user = User.admins.order_id_asc.first
        raise NoAdminError.new('No admin user found to import repositories')
      end

      @group_path, @project_path = File.split(repo_path)
      @group_path = nil if @group_path == '.'
    end

    def create_project_if_needed
      if project = Project.find_by_full_path(full_path)
        log " * #{project.name} (#{full_path}) exists"
        return project
      end

      create_project
    end

    private

    def create_project
      group = find_or_create_group

      project_params = {
        name: project_path,
        path: project_path,
        repository_storage: storage_name,
        namespace_id: group&.id
      }

      project = Projects::CreateService.new(user, project_params).execute

      if project.persisted?
        log " * Created #{project.name} (#{full_path})".color(:green)
        ProjectCacheWorker.perform_async(project.id)
      else
        log " * Failed trying to create #{project.name} (#{full_path})".color(:red)
        log "   Errors: #{project.errors.messages}".color(:red)
      end

      project
    end

    def find_or_create_group
      return nil unless group_path

      if namespace = Namespace.find_by_full_path(group_path)
        log " * Namespace #{group_path} exists.".color(:green)
        return namespace
      end

      create_group_path
    end

    def create_group_path
      group_path_segments = group_path.split('/')

      new_group, parent_group = nil
      partial_path_segments = []
      while subgroup_name = group_path_segments.shift
        partial_path_segments << subgroup_name
        partial_path = partial_path_segments.join('/')

        unless new_group = Group.find_by_full_path(partial_path)
          log " * Creating group #{partial_path}.".color(:green)
          params = {
            path: subgroup_name,
            name: subgroup_name,
            parent: parent_group,
            visibility_level: Gitlab::CurrentSettings.current_application_settings.default_group_visibility
          }
          new_group = Groups::CreateService.new(user, params).execute
        end

        if new_group.persisted?
          log " * Group #{partial_path} (#{new_group.id}) available".color(:green)
        else
          log " * Failed trying to create group #{partial_path}.".color(:red)
          log " * Errors:  #{new_group.errors.messages}".color(:red)
        end
        parent_group = new_group
      end

      new_group
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
