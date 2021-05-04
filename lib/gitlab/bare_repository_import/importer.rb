# frozen_string_literal: true

module Gitlab
  module BareRepositoryImport
    class Importer
      NoAdminError = Class.new(StandardError)

      def self.execute(import_path)
        unless import_path.ends_with?('/')
          import_path = "#{import_path}/"
        end

        repos_to_import = Dir.glob(import_path + '**/*.git')

        unless user = User.admins.order_id_asc.first
          raise NoAdminError, 'No admin user found to import repositories'
        end

        repos_to_import.each do |repo_path|
          bare_repo = Gitlab::BareRepositoryImport::Repository.new(import_path, repo_path)

          unless bare_repo.processable?
            log " * Skipping repo #{bare_repo.repo_path}".color(:yellow)

            next
          end

          log "Processing #{repo_path}".color(:yellow)

          new(user, bare_repo).create_project_if_needed
        end
      end

      # This is called from within a rake task only used by Admins, so allow writing
      # to STDOUT
      def self.log(message)
        puts message # rubocop:disable Rails/Output
      end

      attr_reader :user, :project_name, :bare_repo

      delegate :log, to: :class
      delegate :project_name, :project_full_path, :group_path, :repo_path, :wiki_path, to: :bare_repo

      def initialize(user, bare_repo)
        @user = user
        @bare_repo = bare_repo
      end

      def create_project_if_needed
        if project = Project.find_by_full_path(project_full_path)
          log " * #{project.name} (#{project_full_path}) exists"

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
                                              skip_wiki: bare_repo.wiki_exists?,
                                              import_type: 'bare_repository',
                                              namespace_id: group&.id).execute

        if project.persisted? && mv_repositories(project)
          log " * Created #{project.name} (#{project_full_path})".color(:green)

          project.write_repository_config

          ProjectCacheWorker.perform_async(project.id)
        else
          log " * Failed trying to create #{project.name} (#{project_full_path})".color(:red)
          log "   Errors: #{project.errors.messages}".color(:red) if project.errors.any?
        end

        project
      end

      def mv_repositories(project)
        mv_repo(bare_repo.repo_path, project.repository)

        if bare_repo.wiki_exists?
          mv_repo(bare_repo.wiki_path, project.wiki.repository)
        end

        true
      rescue StandardError => e
        log " * Failed to move repo: #{e.message}".color(:red)

        false
      end

      def mv_repo(path, repository)
        repository.create_from_bundle(bundle(path))
        FileUtils.rm_rf(path)
      end

      def storage_path_for_shard(shard)
        Gitlab.config.repositories.storages[shard].legacy_disk_path
      end

      def find_or_create_groups
        return unless group_path.present?

        log " * Using namespace: #{group_path}"

        Groups::NestedCreateService.new(user, group_path: group_path).execute
      end

      def bundle(repo_path)
        # TODO: we could save some time and disk space by using
        # `git bundle create - --all` and streaming the bundle directly to
        # Gitaly, rather than writing it on disk first
        bundle_path = "#{repo_path}.bundle"
        cmd = %W(#{Gitlab.config.git.bin_path} --git-dir=#{repo_path} bundle create #{bundle_path} --all)
        output, status = Gitlab::Popen.popen(cmd)

        raise output unless status == 0

        bundle_path
      end
    end
  end
end
