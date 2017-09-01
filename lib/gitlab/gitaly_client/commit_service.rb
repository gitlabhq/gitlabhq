module Gitlab
  module GitalyClient
    class CommitService
      # The ID of empty tree.
      # See http://stackoverflow.com/a/40884093/1856239 and https://github.com/git/git/blob/3ad8b5bf26362ac67c9020bf8c30eee54a84f56d/cache.h#L1011-L1012
      EMPTY_TREE_ID = '4b825dc642cb6eb9a060e54bf8d69288fbee4904'.freeze

      def initialize(repository)
        @gitaly_repo = repository.gitaly_repository
        @repository = repository
      end

      def is_ancestor(ancestor_id, child_id)
        request = Gitaly::CommitIsAncestorRequest.new(
          repository: @gitaly_repo,
          ancestor_id: ancestor_id,
          child_id: child_id
        )

        GitalyClient.call(@repository.storage, :commit_service, :commit_is_ancestor, request).value
      end

      def diff_from_parent(commit, options = {})
        request_params = commit_diff_request_params(commit, options)
        request_params[:ignore_whitespace_change] = options.fetch(:ignore_whitespace_change, false)
        request_params[:enforce_limits] = options.fetch(:limits, true)
        request_params[:collapse_diffs] = request_params[:enforce_limits] || !options.fetch(:expanded, true)
        request_params.merge!(Gitlab::Git::DiffCollection.collection_limits(options).to_h)

        request = Gitaly::CommitDiffRequest.new(request_params)
        response = GitalyClient.call(@repository.storage, :diff_service, :commit_diff, request)
        Gitlab::Git::DiffCollection.new(GitalyClient::DiffStitcher.new(response), options.merge(from_gitaly: true))
      end

      def commit_deltas(commit)
        request = Gitaly::CommitDeltaRequest.new(commit_diff_request_params(commit))
        response = GitalyClient.call(@repository.storage, :diff_service, :commit_delta, request)
        response.flat_map do |msg|
          msg.deltas.map { |d| Gitlab::Git::Diff.new(d) }
        end
      end

      def tree_entry(ref, path, limit = nil)
        request = Gitaly::TreeEntryRequest.new(
          repository: @gitaly_repo,
          revision: ref,
          path: path.dup.force_encoding(Encoding::ASCII_8BIT),
          limit: limit.to_i
        )

        response = GitalyClient.call(@repository.storage, :commit_service, :tree_entry, request)
        entry = response.first
        return unless entry.oid.present?

        if entry.type == :BLOB
          rest_of_data = response.reduce("") { |memo, msg| memo << msg.data }
          entry.data += rest_of_data
        end

        entry
      end

      def tree_entries(repository, revision, path)
        request = Gitaly::GetTreeEntriesRequest.new(
          repository: @gitaly_repo,
          revision: GitalyClient.encode(revision),
          path: path.present? ? GitalyClient.encode(path) : '.'
        )

        response = GitalyClient.call(@repository.storage, :commit_service, :get_tree_entries, request)

        response.flat_map do |message|
          message.entries.map do |gitaly_tree_entry|
            entry_path = gitaly_tree_entry.path.dup
            Gitlab::Git::Tree.new(
              id: gitaly_tree_entry.oid,
              root_id: gitaly_tree_entry.root_oid,
              type: gitaly_tree_entry.type.downcase,
              mode: gitaly_tree_entry.mode.to_s(8),
              name: File.basename(entry_path),
              path: entry_path,
              commit_id: gitaly_tree_entry.commit_oid
            )
          end
        end
      end

      def commit_count(ref, options = {})
        request = Gitaly::CountCommitsRequest.new(
          repository: @gitaly_repo,
          revision: ref
        )
        request.after = Google::Protobuf::Timestamp.new(seconds: options[:after].to_i) if options[:after].present?
        request.before = Google::Protobuf::Timestamp.new(seconds: options[:before].to_i) if options[:before].present?
        request.path = options[:path] if options[:path].present?

        GitalyClient.call(@repository.storage, :commit_service, :count_commits, request).count
      end

      def last_commit_for_path(revision, path)
        request = Gitaly::LastCommitForPathRequest.new(
          repository: @gitaly_repo,
          revision: revision.force_encoding(Encoding::ASCII_8BIT),
          path: path.to_s.force_encoding(Encoding::ASCII_8BIT)
        )

        gitaly_commit = GitalyClient.call(@repository.storage, :commit_service, :last_commit_for_path, request).commit
        return unless gitaly_commit

        Gitlab::Git::Commit.new(@repository, gitaly_commit)
      end

      def between(from, to)
        request = Gitaly::CommitsBetweenRequest.new(
          repository: @gitaly_repo,
          from: from,
          to: to
        )

        response = GitalyClient.call(@repository.storage, :commit_service, :commits_between, request)
        consume_commits_response(response)
      end

      def find_all_commits(opts = {})
        request = Gitaly::FindAllCommitsRequest.new(
          repository: @gitaly_repo,
          revision: opts[:ref].to_s,
          max_count: opts[:max_count].to_i,
          skip: opts[:skip].to_i
        )
        request.order = opts[:order].upcase if opts[:order].present?

        response = GitalyClient.call(@repository.storage, :commit_service, :find_all_commits, request)
        consume_commits_response(response)
      end

      def commits_by_message(query, revision: '', path: '', limit: 1000, offset: 0)
        request = Gitaly::CommitsByMessageRequest.new(
          repository: @gitaly_repo,
          query: query,
          revision: revision.to_s.force_encoding(Encoding::ASCII_8BIT),
          path: path.to_s.force_encoding(Encoding::ASCII_8BIT),
          limit: limit.to_i,
          offset: offset.to_i
        )

        response = GitalyClient.call(@repository.storage, :commit_service, :commits_by_message, request)
        consume_commits_response(response)
      end

      def languages(ref = nil)
        request = Gitaly::CommitLanguagesRequest.new(repository: @gitaly_repo, revision: ref || '')
        response = GitalyClient.call(@repository.storage, :commit_service, :commit_languages, request)

        response.languages.map { |l| { value: l.share.round(2), label: l.name, color: l.color, highlight: l.color } }
      end

      def raw_blame(revision, path)
        request = Gitaly::RawBlameRequest.new(
          repository: @gitaly_repo,
          revision: GitalyClient.encode(revision),
          path: GitalyClient.encode(path)
        )

        response = GitalyClient.call(@repository.storage, :commit_service, :raw_blame, request)
        response.reduce("") { |memo, msg| memo << msg.data }
      end

      private

      def commit_diff_request_params(commit, options = {})
        parent_id = commit.parent_ids.first || EMPTY_TREE_ID

        {
          repository: @gitaly_repo,
          left_commit_id: parent_id,
          right_commit_id: commit.id,
          paths: options.fetch(:paths, [])
        }
      end

      def consume_commits_response(response)
        response.flat_map do |message|
          message.commits.map do |gitaly_commit|
            Gitlab::Git::Commit.new(@repository, gitaly_commit)
          end
        end
      end
    end
  end
end
