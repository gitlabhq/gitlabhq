module Gitlab
  class AuthorityAnalyzer
    COMMITS_TO_CONSIDER = 5

    def initialize(merge_request)
      @merge_request = merge_request
      @users = Hash.new(0)
    end

    def calculate(number_of_approvers)
      involved_users

      # Picks most active users from hash like: {user1: 2, user2: 6}
      @users.sort_by { |user, count| -count }.map(&:first).take(number_of_approvers)
    end

    private

    def involved_users
      @repo = @merge_request.target_project.repository

      list_of_involved_files.each do |path|
        @repo.commits(@merge_request.target_branch, path: path, limit: COMMITS_TO_CONSIDER).each do |commit|
          if commit.author && commit.author != @merge_request.author
            @users[commit.author] += 1
          end
        end
      end
    end

    def list_of_involved_files
      diffable = [@merge_request.compare, @merge_request.merge_request_diff].compact
      return [] if diffable.empty?

      compare_diffs = diffable.first.diffs

      return [] unless compare_diffs.present?

      compare_diffs.map do |diff|
        if diff.deleted_file || diff.renamed_file
          diff.old_path
        else
          diff.new_path
        end
      end
    end
  end
end
