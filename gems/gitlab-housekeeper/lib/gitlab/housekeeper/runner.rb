# frozen_string_literal: true

require 'active_support/core_ext/string'
require 'gitlab/housekeeper/keep'
require 'gitlab/housekeeper/gitlab_client'
require 'gitlab/housekeeper/git'
require 'gitlab/housekeeper/change'
require 'awesome_print'
require 'digest'

module Gitlab
  module Housekeeper
    class Runner
      def initialize(max_mrs: 1, dry_run: false, keeps: nil, filter_identifiers: [])
        @max_mrs = max_mrs
        @dry_run = dry_run
        @logger = Logger.new($stdout)
        require_keeps

        @keeps = if keeps
                   keeps.map { |k| k.is_a?(String) ? k.constantize : k }
                 else
                   all_keeps
                 end

        @filter_identifiers = filter_identifiers
      end

      def run
        created = 0

        git.with_branch_from_branch do
          @keeps.each do |keep_class|
            keep = keep_class.new
            keep.each_change do |change|
              unless change.valid?
                puts "Ignoring invalid change from: #{keep_class}"
                next
              end

              branch_name = git.commit_in_branch(change)
              add_standard_change_data(change)

              # Must be done after we commit so that we don't keep around changed files. We could checkout those files
              # but then it might be riskier in local development in case we lose unrelated changes.
              unless change.matches_filters?(@filter_identifiers)
                puts "Skipping change: #{change.identifiers} due to not matching filter"
                next
              end

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

      def add_standard_change_data(change)
        change.labels ||= []
        change.labels << 'automation:gitlab-housekeeper-authored'
      end

      def git
        @git ||= ::Gitlab::Housekeeper::Git.new(logger: @logger)
      end

      def require_keeps
        Dir.glob("keeps/*.rb").each do |f|
          require(Pathname(f).expand_path.to_s)
        end
      end

      def dry_run(change, branch_name)
        puts "=> #{change.identifiers.join(': ')}".purple

        puts '=> Title:'.purple
        puts change.title.purple
        puts

        puts '=> Description:'
        puts change.description
        puts

        if change.labels.present?
          puts '=> Attributes:'
          puts "Labels: #{change.labels.join(', ')}"
          puts
        end

        puts '=> Diff:'
        puts Shell.execute('git', '--no-pager', 'diff', '--color=always', 'master', branch_name, '--',
          *change.changed_files)
        puts
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
          change: change,
          source_project_id: housekeeper_fork_project_id,
          source_branch: branch_name,
          target_branch: 'master',
          target_project_id: housekeeper_target_project_id,
          update_title: !non_housekeeper_changes.include?(:title),
          update_description: !non_housekeeper_changes.include?(:description),
          update_labels: !non_housekeeper_changes.include?(:labels),
          update_reviewers: !non_housekeeper_changes.include?(:reviewers)
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
