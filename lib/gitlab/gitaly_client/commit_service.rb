# frozen_string_literal: true

module Gitlab
  module GitalyClient
    class CommitService
      include Gitlab::EncodingHelper

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
                    Gitlab::Git::EMPTY_TREE_ID
                  else
                    if from.respond_to?(:oid)
                      # This is meant to match a Rugged::Commit. This should be impossible in
                      # the future.
                      from.oid
                    else
                      from
                    end
                  end

        to_id = case to
                when NilClass
                  Gitlab::Git::EMPTY_TREE_ID
                else
                  if to.respond_to?(:oid)
                    # This is meant to match a Rugged::Commit. This should be impossible in
                    # the future.
                    to.oid
                  else
                    to
                  end
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
        response = GitalyClient.call(@repository.storage, :diff_service, :commit_delta, request, timeout: GitalyClient.fast_timeout)
        response.flat_map { |msg| msg.deltas }
      end

      def tree_entry(ref, path, limit = nil)
        if Pathname.new(path).cleanpath.to_s.start_with?('../')
          # The TreeEntry RPC should return an empty response in this case but in
          # Gitaly 0.107.0 and earlier we get an exception instead. This early return
          # saves us a Gitaly roundtrip while also avoiding the exception.
          return
        end

        request = Gitaly::TreeEntryRequest.new(
          repository: @gitaly_repo,
          revision: encode_binary(ref),
          path: encode_binary(path),
          limit: limit.to_i
        )

        response = GitalyClient.call(@repository.storage, :commit_service, :tree_entry, request, timeout: GitalyClient.medium_timeout)

        entry = nil
        data = []
        response.each do |msg|
          if entry.nil?
            entry = msg

            break unless entry.type == :BLOB
          end

          data << msg.data
        end
        entry.data = data.join

        entry unless entry.oid.blank?
      rescue GRPC::NotFound
        nil
      end

      def tree_entries(repository, revision, path, recursive)
        request = Gitaly::GetTreeEntriesRequest.new(
          repository: @gitaly_repo,
          revision: encode_binary(revision),
          path: path.present? ? encode_binary(path) : '.',
          recursive: recursive
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
          revision: encode_binary(ref),
          all: !!options[:all],
          first_parent: !!options[:first_parent]
        )
        request.after = Google::Protobuf::Timestamp.new(seconds: options[:after].to_i) if options[:after].present?
        request.before = Google::Protobuf::Timestamp.new(seconds: options[:before].to_i) if options[:before].present?
        request.path = encode_binary(options[:path]) if options[:path].present?
        request.max_count = options[:max_count] if options[:max_count].present?

        GitalyClient.call(@repository.storage, :commit_service, :count_commits, request, timeout: GitalyClient.medium_timeout).count
      end

      def diverging_commit_count(from, to, max_count:)
        request = Gitaly::CountDivergingCommitsRequest.new(
          repository: @gitaly_repo,
          from: encode_binary(from),
          to: encode_binary(to),
          max_count: max_count
        )
        response = GitalyClient.call(@repository.storage, :commit_service, :count_diverging_commits, request, timeout: GitalyClient.medium_timeout)
        [response.left_count, response.right_count]
      end

      def list_last_commits_for_tree(revision, path, offset: 0, limit: 25, literal_pathspec: false)
        request = Gitaly::ListLastCommitsForTreeRequest.new(
          repository: @gitaly_repo,
          revision: encode_binary(revision),
          path: encode_binary(path.to_s),
          offset: offset,
          limit: limit,
          global_options: parse_global_options!(literal_pathspec: literal_pathspec)
        )

        response = GitalyClient.call(@repository.storage, :commit_service, :list_last_commits_for_tree, request, timeout: GitalyClient.medium_timeout)

        response.each_with_object({}) do |gitaly_response, hsh|
          gitaly_response.commits.each do |commit_for_tree|
            hsh[commit_for_tree.path_bytes] = Gitlab::Git::Commit.new(@repository, commit_for_tree.commit)
          end
        end
      end

      def last_commit_for_path(revision, path, literal_pathspec: false)
        request = Gitaly::LastCommitForPathRequest.new(
          repository: @gitaly_repo,
          revision: encode_binary(revision),
          path: encode_binary(path.to_s),
          global_options: parse_global_options!(literal_pathspec: literal_pathspec)
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

      def diff_stats(left_commit_sha, right_commit_sha)
        request = Gitaly::DiffStatsRequest.new(
          repository: @gitaly_repo,
          left_commit_id: left_commit_sha,
          right_commit_id: right_commit_sha
        )

        response = GitalyClient.call(@repository.storage, :diff_service, :diff_stats, request, timeout: GitalyClient.medium_timeout)
        response.flat_map(&:stats)
      end

      def find_changed_paths(commits)
        request = Gitaly::FindChangedPathsRequest.new(
          repository: @gitaly_repo,
          commits: commits
        )

        response = GitalyClient.call(@repository.storage, :diff_service, :find_changed_paths, request, timeout: GitalyClient.medium_timeout)
        response.flat_map do |msg|
          msg.paths.map do |path|
            Gitlab::Git::ChangedPath.new(
              status: path.status,
              path:  EncodingHelper.encode!(path.path)
            )
          end
        end
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

      def list_commits(revisions)
        request = Gitaly::ListCommitsRequest.new(
          repository: @gitaly_repo,
          revisions: Array.wrap(revisions)
        )

        response = GitalyClient.call(@repository.storage, :commit_service, :list_commits, request, timeout: GitalyClient.medium_timeout)
        consume_commits_response(response)
      end

      def list_commits_by_oid(oids)
        return [] if oids.empty?

        request = Gitaly::ListCommitsByOidRequest.new(repository: @gitaly_repo, oid: oids)

        response = GitalyClient.call(@repository.storage, :commit_service, :list_commits_by_oid, request, timeout: GitalyClient.medium_timeout)
        consume_commits_response(response)
      rescue GRPC::NotFound # If no repository is found, happens mainly during testing
        []
      end

      def commits_by_message(query, revision: '', path: '', limit: 1000, offset: 0, literal_pathspec: true)
        request = Gitaly::CommitsByMessageRequest.new(
          repository: @gitaly_repo,
          query: query,
          revision: encode_binary(revision),
          path: encode_binary(path),
          limit: limit.to_i,
          offset: offset.to_i,
          global_options: parse_global_options!(literal_pathspec: literal_pathspec)
        )

        response = GitalyClient.call(@repository.storage, :commit_service, :commits_by_message, request, timeout: GitalyClient.medium_timeout)
        consume_commits_response(response)
      end

      def languages(ref = nil)
        request = Gitaly::CommitLanguagesRequest.new(repository: @gitaly_repo, revision: ref || '')
        response = GitalyClient.call(@repository.storage, :commit_service, :commit_languages, request, timeout: GitalyClient.long_timeout)

        response.languages.map { |l| { value: l.share.round(2), label: l.name, color: l.color, highlight: l.color } }
      end

      def raw_blame(revision, path)
        request = Gitaly::RawBlameRequest.new(
          repository: @gitaly_repo,
          revision: encode_binary(revision),
          path: encode_binary(path)
        )

        response = GitalyClient.call(@repository.storage, :commit_service, :raw_blame, request, timeout: GitalyClient.medium_timeout)
        response.reduce([]) { |memo, msg| memo << msg.data }.join
      end

      def find_commit(revision)
        return call_find_commit(revision) unless Gitlab::SafeRequestStore.active?

        # We don't use Gitlab::SafeRequestStore.fetch(key) { ... } directly
        # because `revision` can be a branch name, so we can't use it as a key
        # as it could point to another commit later on (happens a lot in
        # tests).
        key = {
          storage: @gitaly_repo.storage_name,
          relative_path: @gitaly_repo.relative_path,
          commit_id: revision
        }
        return Gitlab::SafeRequestStore[key] if Gitlab::SafeRequestStore.exist?(key)

        commit = call_find_commit(revision)

        if GitalyClient.ref_name_caching_allowed?
          Gitlab::SafeRequestStore[key] = commit
          return commit
        end

        return unless commit

        key[:commit_id] = commit.id
        Gitlab::SafeRequestStore[key] = commit
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
          all:          !!options[:all],
          first_parent: !!options[:first_parent],
          global_options: parse_global_options!(options),
          disable_walk: true, # This option is deprecated. The 'walk' implementation is being removed.
          trailers: options[:trailers]
        )
        request.after    = GitalyClient.timestamp(options[:after]) if options[:after]
        request.before   = GitalyClient.timestamp(options[:before]) if options[:before]
        request.revision = encode_binary(options[:ref]) if options[:ref]
        request.author   = encode_binary(options[:author]) if options[:author]
        request.order    = options[:order].upcase.sub('DEFAULT', 'NONE') if options[:order].present?

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

        response = GitalyClient.call(@repository.storage, :commit_service, :filter_shas_with_signatures, enum, timeout: GitalyClient.fast_timeout)
        response.flat_map do |msg|
          msg.shas.map { |sha| EncodingHelper.encode!(sha) }
        end
      end

      def get_commit_signatures(commit_ids)
        request = Gitaly::GetCommitSignaturesRequest.new(repository: @gitaly_repo, commit_ids: commit_ids)
        response = GitalyClient.call(@repository.storage, :commit_service, :get_commit_signatures, request, timeout: GitalyClient.fast_timeout)

        signatures = Hash.new { |h, k| h[k] = [+''.b, +''.b] }
        current_commit_id = nil

        response.each do |message|
          current_commit_id = message.commit_id if message.commit_id.present?

          signatures[current_commit_id].first << message.signature
          signatures[current_commit_id].last << message.signed_text
        end

        signatures
      rescue GRPC::InvalidArgument => ex
        raise ArgumentError, ex
      end

      def get_commit_messages(commit_ids)
        request = Gitaly::GetCommitMessagesRequest.new(repository: @gitaly_repo, commit_ids: commit_ids)
        response = GitalyClient.call(@repository.storage, :commit_service, :get_commit_messages, request, timeout: GitalyClient.fast_timeout)

        messages = Hash.new { |h, k| h[k] = +''.b }
        current_commit_id = nil

        response.each do |rpc_message|
          current_commit_id = rpc_message.commit_id if rpc_message.commit_id.present?

          messages[current_commit_id] << rpc_message.message
        end

        messages
      end

      def list_commits_by_ref_name(refs)
        request = Gitaly::ListCommitsByRefNameRequest
          .new(repository: @gitaly_repo, ref_names: refs.map { |ref| encode_binary(ref) })

        response = GitalyClient.call(@repository.storage, :commit_service, :list_commits_by_ref_name, request, timeout: GitalyClient.medium_timeout)

        commit_refs = response.flat_map do |message|
          message.commit_refs.map do |commit_ref|
            [encode_utf8(commit_ref.ref_name), Gitlab::Git::Commit.new(@repository, commit_ref.commit)]
          end
        end

        Hash[commit_refs]
      end

      private

      def parse_global_options!(options)
        literal_pathspec = options.delete(:literal_pathspec)
        Gitaly::GlobalOptions.new(literal_pathspecs: literal_pathspec)
      end

      def call_commit_diff(request_params, options = {})
        request_params[:ignore_whitespace_change] = options.fetch(:ignore_whitespace_change, false)
        request_params[:enforce_limits] = options.fetch(:limits, true)
        request_params[:collapse_diffs] = !options.fetch(:expanded, true)
        request_params.merge!(Gitlab::Git::DiffCollection.limits(options).to_h)

        request = Gitaly::CommitDiffRequest.new(request_params)
        response = GitalyClient.call(@repository.storage, :diff_service, :commit_diff, request, timeout: GitalyClient.medium_timeout)
        GitalyClient::DiffStitcher.new(response)
      end

      def diff_from_parent_request_params(commit, options = {})
        parent_id = commit.parent_ids.first || Gitlab::Git::EMPTY_TREE_ID

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

      def encode_repeated(array)
        Google::Protobuf::RepeatedField.new(:bytes, array.map { |s| encode_binary(s) } )
      end

      def call_find_commit(revision)
        request = Gitaly::FindCommitRequest.new(
          repository: @gitaly_repo,
          revision: encode_binary(revision)
        )

        response = GitalyClient.call(@repository.storage, :commit_service, :find_commit, request, timeout: GitalyClient.medium_timeout)

        response.commit
      end
    end
  end
end
