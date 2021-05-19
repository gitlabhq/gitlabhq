# frozen_string_literal: true

module MergeRequests
  class AddContextService < MergeRequests::BaseService
    def execute
      return error("You are not allowed to access the requested resource", 403) unless current_user&.can?(:update_merge_request, merge_request)
      return error("Context commits: #{duplicates} are already created", 400) unless duplicates.empty?
      return error("One or more context commits' sha is not valid.", 400) if commits.size != commit_ids.size

      context_commit_ids = []
      MergeRequestContextCommit.transaction do
        context_commit_ids = MergeRequestContextCommit.bulk_insert(context_commit_rows, return_ids: true)
        MergeRequestContextCommitDiffFile.bulk_insert(diff_rows(context_commit_ids))
      end

      commits
    end

    private

    def raw_repository
      project.repository.raw_repository
    end

    def merge_request
      params[:merge_request]
    end

    def commit_ids
      params[:commits]
    end

    def commits
      project.repository.commits_by(oids: commit_ids)
    end

    def context_commit_rows
      @context_commit_rows ||= build_context_commit_rows(merge_request.id, commits)
    end

    def diff_rows(context_commit_ids)
      @diff_rows ||= build_diff_rows(raw_repository, commits, context_commit_ids)
    end

    def encode_in_base64?(diff_text)
      (diff_text.encoding == Encoding::BINARY && !diff_text.ascii_only?) ||
        diff_text.include?("\0")
    end

    def duplicates
      existing_oids = merge_request.merge_request_context_commits.map { |commit| commit.sha.to_s }
      existing_oids.select do |existing_oid|
        commit_ids.count { |commit_id| existing_oid.start_with?(commit_id) } > 0
      end
    end

    def build_context_commit_rows(merge_request_id, commits)
      commits.map.with_index do |commit, index|
        # generate context commit information for given commit
        commit_hash = commit.to_hash.except(:parent_ids)
        sha = Gitlab::Database::ShaAttribute.serialize(commit_hash.delete(:id))
        commit_hash.merge(
          merge_request_id: merge_request_id,
          relative_order: index,
          sha: sha,
          authored_date: Gitlab::Database.sanitize_timestamp(commit_hash[:authored_date]),
          committed_date: Gitlab::Database.sanitize_timestamp(commit_hash[:committed_date]),
          trailers: commit_hash.fetch(:trailers, {}).to_json
        )
      end
    end

    def build_diff_rows(raw_repository, commits, context_commit_ids)
      diff_rows = []
      diff_order = 0

      commits.flat_map.with_index do |commit, index|
        commit_hash = commit.to_hash.except(:parent_ids)
        sha = Gitlab::Database::ShaAttribute.serialize(commit_hash.delete(:id))
        # generate context commit diff information for given commit
        diffs = commit.diffs

        compare = Gitlab::Git::Compare.new(
          raw_repository,
          diffs.diff_refs.start_sha,
          diffs.diff_refs.head_sha
        )
        compare.diffs.map do |diff|
          diff_hash = diff.to_hash.merge(
            sha: sha,
            binary: false,
            merge_request_context_commit_id: context_commit_ids[index],
            relative_order: diff_order
          )

          # Compatibility with old diffs created with Psych.
          diff_hash.tap do |hash|
            diff_text = hash[:diff]

            if encode_in_base64?(diff_text)
              hash[:binary] = true
              hash[:diff] = [diff_text].pack('m0')
            end
          end

          # Increase order for commit so when present the diffs we can use it to keep order
          diff_order += 1
          diff_rows << diff_hash
        end
      end

      diff_rows
    end
  end
end
