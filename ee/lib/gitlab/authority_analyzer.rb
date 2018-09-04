module Gitlab
  class AuthorityAnalyzer
    COMMITS_TO_CONSIDER = 25

    def initialize(merge_request, skip_user)
      @merge_request = merge_request
      @skip_user = skip_user
      @users = Hash.new(0)
    end

    # rubocop: disable CodeReuse/ActiveRecord
    def calculate(number_of_approvers)
      involved_users

      # Picks most active users from hash like: {user1: 2, user2: 6}
      @users.sort_by { |user, count| -count }.map(&:first).take(number_of_approvers)
    end
    # rubocop: enable CodeReuse/ActiveRecord

    private

    def involved_users
      @repo = @merge_request.target_project.repository

      @repo.commits(@merge_request.target_branch, path: list_of_involved_files, limit: COMMITS_TO_CONSIDER).each do |commit|
        if commit.author && commit.author != @skip_user
          @users[commit.author] += 1
        end
      end
    end

    def list_of_involved_files
      diffable = [@merge_request.compare, @merge_request.merge_request_diff].compact
      return [] if diffable.empty?

      compare_diffs = diffable.first.raw_diffs

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
