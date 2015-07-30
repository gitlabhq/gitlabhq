module Gitlab
  class AuthorityAnalyzer
    COMMITS_TO_CONSIDERATION = 5

    def initialize(data, current_user)
      @source_branch = data[:source_branch]
      @source_project = data[:source_project]
      @target_branch = data[:target_branch]
      @target_project = data[:target_project]
      @current_user = current_user
      @users = {}
    end

    def calculate(number_of_approvers)
      involved_users

      # Picks most active users from hash like: {user1: 2, user2: 6}
      @users.to_a.sort{|a, b| b.last <=> a.last }[0..number_of_approvers].map(&:first)
    end

    private

    def involved_users
      @repo = @target_project.repository

      list_of_involved_files.each do |path|
        @repo.commits(@target_branch, path, COMMITS_TO_CONSIDERATION).each do |commit|
          add_user_to_list(commit.author) unless commit.author.nil?
        end
      end
    end

    def add_user_to_list(user)
      @users[user] = @users[user].nil? ? 1 : (@users[user] + 1)
    end

    def list_of_involved_files
      compare_result = CompareService.new.execute(
        @current_user,
        @source_project,
        @source_branch,
        @target_project,
        @target_branch,
      )

      commits = compare_result.commits

      if commits.present? && compare_result.diffs.present?
        return compare_result.diffs.map do |diff|
          case true
          when diff.deleted_file, diff.renamed_file
            diff.old_path
          else
            diff.new_path
          end
        end
      end

      []
    end
  end
end
