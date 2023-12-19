# frozen_string_literal: true

require 'gitlab/housekeeper/keep'
require "gitlab/housekeeper/gitlab_client"
require "gitlab/housekeeper/git"
require 'digest'

module Gitlab
  module Housekeeper
    Change = Struct.new(:identifiers, :title, :description, :changed_files)

    class Runner
      def initialize(max_mrs: 1, dry_run: false, require: [], keeps: nil)
        @max_mrs = max_mrs
        @dry_run = dry_run
        @logger = Logger.new($stdout)
        require_keeps(require)

        @keeps = if keeps
                   keeps.map { |k| k.is_a?(String) ? k.constantize : k }
                 else
                   all_keeps
                 end
      end

      def run
        created = 0

        git.with_branch_from_branch do
          @keeps.each do |keep_class|
            keep = keep_class.new
            keep.each_change do |change|
              branch_name = git.commit_in_branch(change)

              if @dry_run
                dry_run(change, branch_name)
              else
                create(change, branch_name)
              end

              created += 1
              break if created >= @max_mrs
            end
            break if created >= @max_mrs
          end
        end

        puts "Housekeeper created #{created} MRs"
      end

      def git
        @git ||= ::Gitlab::Housekeeper::Git.new(logger: @logger)
      end

      def require_keeps(files)
        files.each do |r|
          require(Pathname(r).expand_path.to_s)
        end
      end

      def dry_run(change, branch_name)
        puts
        puts "# #{change.title}"
        puts
        puts change.description
        puts
        puts Shell.execute('git', '--no-pager', 'diff', 'master', branch_name, '--', *change.changed_files)
      end

      def create(change, branch_name)
        dry_run(change, branch_name)

        non_housekeeper_changes = gitlab_client.non_housekeeper_changes(
          source_project_id: housekeeper_fork_project_id,
          source_branch: branch_name,
          target_branch: 'master',
          target_project_id: housekeeper_target_project_id
        )

        unless non_housekeeper_changes.include?(:code)
          Shell.execute('git', 'push', '-f', 'housekeeper', "#{branch_name}:#{branch_name}")
        end

        gitlab_client.create_or_update_merge_request(
          source_project_id: housekeeper_fork_project_id,
          title: change.title,
          description: change.description,
          source_branch: branch_name,
          target_branch: 'master',
          target_project_id: housekeeper_target_project_id,
          update_title: !non_housekeeper_changes.include?(:title),
          update_description: !non_housekeeper_changes.include?(:description)
        )
      end

      def housekeeper_fork_project_id
        ENV.fetch('HOUSEKEEPER_FORK_PROJECT_ID')
      end

      def housekeeper_target_project_id
        ENV.fetch('HOUSEKEEPER_TARGET_PROJECT_ID')
      end

      def gitlab_client
        @gitlab_client ||= GitlabClient.new
      end

      def all_keeps
        @all_keeps ||= ObjectSpace.each_object(Class).select { |klass| klass < Keep }
      end
    end
  end
end
