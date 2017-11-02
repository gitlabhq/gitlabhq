module Gitlab
  class BareRepositoryImporter
    NoAdminError = Class.new(StandardError)

    def self.execute(import_path)
      import_path << '/' unless import_path.ends_with?('/')
      repos_to_import = Dir.glob(import_path + '/**/*.git')

      repos_to_import.each do |repo_path|
        if repo_path.end_with?('.wiki.git')
          log " * Skipping wiki repo"
          next
        end

        log "Processing #{repo_path}".color(:yellow)

        repo_relative_path = repo_path.sub(/\A#{import_path}\//, '').sub(/\.git$/, '') # Remove root path and `.git` at the end
        new(repo_relative_path).create_project_if_needed
      end
    end

    attr_reader :storage_name, :full_path, :group_path, :user, :project_name
    delegate :log, to: :class

    def initialize(repo_path)
      unless @user = User.admins.order_id_asc.first
        raise NoAdminError.new('No admin user found to import repositories')
      end

      @full_path = repo_path

      # Split path into 'all/the/namespaces' and 'project_name'
      @group_path, _sep, @project_name = @full_path.rpartition('/')
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
      group = find_or_create_groups

      project = Projects::CreateService.new(user,
                                            name: project_name,
                                            path: full_path,
                                            namespace_id: group&.id).execute

      if project.persisted?
        log " * Created #{project.name} (#{full_path})".color(:green)
        ProjectCacheWorker.perform_async(project.id)
      else
        log " * Failed trying to create #{project.name} (#{full_path})".color(:red)
        log "   Errors: #{project.errors.messages}".color(:red)
      end

      project
    end

    def find_or_create_groups
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
