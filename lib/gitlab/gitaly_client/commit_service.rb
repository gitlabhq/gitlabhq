module Gitlab
  module GitalyClient
    class CommitService
      include Gitlab::EncodingHelper

      # The ID of empty tree.
      # See http://stackoverflow.com/a/40884093/1856239 and https://github.com/git/git/blob/3ad8b5bf26362ac67c9020bf8c30eee54a84f56d/cache.h#L1011-L1012
      EMPTY_TREE_ID = '4b825dc642cb6eb9a060e54bf8d69288fbee4904'.freeze

      def initialize(repository)
        @gitaly_repo = repository.gitaly_repository
        @repository = repository
      end

      def ls_files(revision)
        request = Gitaly::ListFilesRequest.new(
          repository: @gitaly_repo,
          revision: encode_binary(revision)
        )

        response = GitalyClient.call(@repository.storage, :commit_service, :list_files, request, timeout: GitalyClient.medium_timeout)
        response.flat_map do |msg|
          msg.paths.map { |d| EncodingHelper.encode!(d.dup) }
        end
      end

      def ancestor?(ancestor_id, child_id)
        request = Gitaly::CommitIsAncestorRequest.new(
          repository: @gitaly_repo,
          ancestor_id: ancestor_id,
          child_id: child_id
        )

        GitalyClient.call(@repository.storage, :commit_service, :commit_is_ancestor, request, timeout: GitalyClient.fast_timeout).value
      end

      def diff(from, to, options = {})
        from_id = case from
                  when NilClass
                    EMPTY_TREE_ID
                  when Rugged::Commit
                    from.oid
                  else
                    from
                  end

        to_id = case to
                when NilClass
                  EMPTY_TREE_ID
                when Rugged::Commit
                  to.oid
                else
                  to
                end

        request_params = diff_between_commits_request_params(from_id, to_id, options)

        call_commit_diff(request_params, options)
      end

      def diff_from_parent(commit, options = {})
        request_params = diff_from_parent_request_params(commit, options)

        call_commit_diff(request_params, options)
      end

      def commit_deltas(commit)
        request = Gitaly::CommitDeltaRequest.new(diff_from_parent_request_params(commit))
        response = GitalyClient.call(@repository.storage, :diff_service, :commit_delta, request)

        response.flat_map { |msg| msg.deltas }
      end

      def tree_entry(ref, path, limit = nil)
        request = Gitaly::TreeEntryRequest.new(
          repository: @gitaly_repo,
          revision: ref,
          path: encode_binary(path),
          limit: limit.to_i
        )

        response = GitalyClient.call(@repository.storage, :commit_service, :tree_entry, request, timeout: GitalyClient.medium_timeout)

        entry = nil
        data = ''
        response.each do |msg|
          if entry.nil?
            entry = msg

            break unless entry.type == :BLOB
          end

          data << msg.data
        end
        entry.data = data

        entry unless entry.oid.blank?
      end

      def tree_entries(repository, revision, path)
        request = Gitaly::GetTreeEntriesRequest.new(
          repository: @gitaly_repo,
          revision: encode_binary(revision),
          path: path.present? ? encode_binary(path) : '.'
        )

        response = GitalyClient.call(@repository.storage, :commit_service, :get_tree_entries, request, timeout: GitalyClient.medium_timeout)

        response.flat_map do |message|
          message.entries.map do |gitaly_tree_entry|
            Gitlab::Git::Tree.new(
              id: gitaly_tree_entry.oid,
              root_id: gitaly_tree_entry.root_oid,
              type: gitaly_tree_entry.type.downcase,
              mode: gitaly_tree_entry.mode.to_s(8),
              name: File.basename(gitaly_tree_entry.path),
              path: encode_binary(gitaly_tree_entry.path),
              flat_path: encode_binary(gitaly_tree_entry.flat_path),
              commit_id: gitaly_tree_entry.commit_oid
            )
          end
        end
      end

      def commit_count(ref, options = {})
        request = Gitaly::CountCommitsRequest.new(
          repository: @gitaly_repo,
          revision: encode_binary(ref)
        )
        request.after = Google::Protobuf::Timestamp.new(seconds: options[:after].to_i) if options[:after].present?
        request.before = Google::Protobuf::Timestamp.new(seconds: options[:before].to_i) if options[:before].present?
        request.path = encode_binary(options[:path]) if options[:path].present?
        request.max_count = options[:max_count] if options[:max_count].present?

        GitalyClient.call(@repository.storage, :commit_service, :count_commits, request, timeout: GitalyClient.medium_timeout).count
      end

      def last_commit_for_path(revision, path)
        request = Gitaly::LastCommitForPathRequest.new(
          repository: @gitaly_repo,
          revision: encode_binary(revision),
          path: encode_binary(path.to_s)
        )

        gitaly_commit = GitalyClient.call(@repository.storage, :commit_service, :last_commit_for_path, request, timeout: GitalyClient.fast_timeout).commit
        return unless gitaly_commit

        Gitlab::Git::Commit.new(@repository, gitaly_commit)
      end

      def between(from, to)
        request = Gitaly::CommitsBetweenRequest.new(
          repository: @gitaly_repo,
          from: from,
          to: to
        )

        response = GitalyClient.call(@repository.storage, :commit_service, :commits_between, request, timeout: GitalyClient.medium_timeout)
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

        response = GitalyClient.call(@repository.storage, :commit_service, :find_all_commits, request, timeout: GitalyClient.medium_timeout)
        consume_commits_response(response)
      end

      def list_commits_by_oid(oids)
        request = Gitaly::ListCommitsByOidRequest.new(repository: @gitaly_repo, oid: oids)

        response = GitalyClient.call(@repository.storage, :commit_service, :list_commits_by_oid, request, timeout: GitalyClient.medium_timeout)
        consume_commits_response(response)
      rescue GRPC::Unknown # If no repository is found, happens mainly during testing
        []
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

        response = GitalyClient.call(@repository.storage, :commit_service, :commits_by_message, request, timeout: GitalyClient.medium_timeout)
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
          revision: encode_binary(revision),
          path: encode_binary(path)
        )

        response = GitalyClient.call(@repository.storage, :commit_service, :raw_blame, request, timeout: GitalyClient.medium_timeout)
        response.reduce("") { |memo, msg| memo << msg.data }
      end

      def find_commit(revision)
        request = Gitaly::FindCommitRequest.new(
          repository: @gitaly_repo,
          revision: encode_binary(revision)
        )

        response = GitalyClient.call(@repository.storage, :commit_service, :find_commit, request, timeout: GitalyClient.medium_timeout)

        response.commit
      end

      def patch(revision)
        request = Gitaly::CommitPatchRequest.new(
          repository: @gitaly_repo,
          revision: encode_binary(revision)
        )
        response = GitalyClient.call(@repository.storage, :diff_service, :commit_patch, request, timeout: GitalyClient.medium_timeout)

        response.sum(&:data)
      end

      def commit_stats(revision)
        request = Gitaly::CommitStatsRequest.new(
          repository: @gitaly_repo,
          revision: encode_binary(revision)
        )
        GitalyClient.call(@repository.storage, :commit_service, :commit_stats, request, timeout: GitalyClient.medium_timeout)
      end

      def find_commits(options)
        request = Gitaly::FindCommitsRequest.new(
          repository:   @gitaly_repo,
          limit:        options[:limit],
          offset:       options[:offset],
          follow:       options[:follow],
          skip_merges:  options[:skip_merges],
          disable_walk: options[:disable_walk]
        )
        request.after    = GitalyClient.timestamp(options[:after]) if options[:after]
        request.before   = GitalyClient.timestamp(options[:before]) if options[:before]
        request.revision = encode_binary(options[:ref]) if options[:ref]

        request.paths = encode_repeated(Array(options[:path])) if options[:path].present?

        response = GitalyClient.call(@repository.storage, :commit_service, :find_commits, request, timeout: GitalyClient.medium_timeout)

        consume_commits_response(response)
      end

      def filter_shas_with_signatures(shas)
        request = Gitaly::FilterShasWithSignaturesRequest.new(repository: @gitaly_repo)

        enum = Enumerator.new do |y|
          shas.each_slice(20) do |revs|
            request.shas = encode_repeated(revs)

            y.yield request

            request = Gitaly::FilterShasWithSignaturesRequest.new
          end
        end

        response = GitalyClient.call(@repository.storage, :commit_service, :filter_shas_with_signatures, enum)

        response.flat_map do |msg|
          msg.shas.map { |sha| EncodingHelper.encode!(sha) }
        end
      end

      private

      def call_commit_diff(request_params, options = {})
        request_params[:ignore_whitespace_change] = options.fetch(:ignore_whitespace_change, false)
        request_params[:enforce_limits] = options.fetch(:limits, true)
        request_params[:collapse_diffs] = request_params[:enforce_limits] || !options.fetch(:expanded, true)
        request_params.merge!(Gitlab::Git::DiffCollection.collection_limits(options).to_h)

        request = Gitaly::CommitDiffRequest.new(request_params)
        response = GitalyClient.call(@repository.storage, :diff_service, :commit_diff, request, timeout: GitalyClient.medium_timeout)
        GitalyClient::DiffStitcher.new(response)
      end

      def diff_from_parent_request_params(commit, options = {})
        parent_id = commit.parent_ids.first || EMPTY_TREE_ID

        diff_between_commits_request_params(parent_id, commit.id, options)
      end

      def diff_between_commits_request_params(from_id, to_id, options)
        {
          repository: @gitaly_repo,
          left_commit_id: from_id,
          right_commit_id: to_id,
          paths: options.fetch(:paths, []).compact.map { |path| encode_binary(path) }
        }
      end

      def consume_commits_response(response)
        response.flat_map do |message|
          message.commits.map do |gitaly_commit|
            Gitlab::Git::Commit.new(@repository, gitaly_commit)
          end
        end
      end

      def encode_repeated(a)
        Google::Protobuf::RepeatedField.new(:bytes, a.map { |s| encode_binary(s) } )
      end
    end
  end
end
