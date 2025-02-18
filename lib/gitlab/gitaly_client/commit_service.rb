# frozen_string_literal: true

module Gitlab
  module GitalyClient
    class CommitService
      include Gitlab::EncodingHelper
      include WithFeatureFlagActors

      WHITESPACE_CHANGES = {
        'ignore_all_spaces' => Gitaly::CommitDiffRequest::WhitespaceChanges::WHITESPACE_CHANGES_IGNORE_ALL,
        'ignore_spaces' => Gitaly::CommitDiffRequest::WhitespaceChanges::WHITESPACE_CHANGES_IGNORE,
        'unspecified' => Gitaly::CommitDiffRequest::WhitespaceChanges::WHITESPACE_CHANGES_UNSPECIFIED
      }.freeze

      MERGE_COMMIT_DIFF_MODES = {
        all_parents: Gitaly::FindChangedPathsRequest::MergeCommitDiffMode::MERGE_COMMIT_DIFF_MODE_ALL_PARENTS,
        include_merges: Gitaly::FindChangedPathsRequest::MergeCommitDiffMode::MERGE_COMMIT_DIFF_MODE_INCLUDE_MERGES
      }.freeze

      TREE_ENTRIES_DEFAULT_LIMIT = 100_000

      def initialize(repository)
        @gitaly_repo = repository.gitaly_repository
        @repository = repository

        self.repository_actor = repository
      end

      def ls_files(revision)
        request = Gitaly::ListFilesRequest.new(
          repository: @gitaly_repo,
          revision: encode_binary(revision)
        )

        response = gitaly_client_call(@repository.storage, :commit_service, :list_files, request, timeout: GitalyClient.medium_timeout)
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

        gitaly_client_call(@repository.storage, :commit_service, :commit_is_ancestor, request, timeout: GitalyClient.fast_timeout).value
      end

      def diff(from, to, options = {})
        from_id = from || @repository.empty_tree_id
        to_id = to || @repository.empty_tree_id

        request_params = diff_between_commits_request_params(from_id, to_id, options)

        call_commit_diff(request_params, options)
      end

      def diff_from_parent(commit, options = {})
        request_params = diff_from_parent_request_params(commit, options)

        call_commit_diff(request_params, options)
      end

      def commit_deltas(commit)
        request = Gitaly::CommitDeltaRequest.new(diff_from_parent_request_params(commit))
        response = gitaly_client_call(@repository.storage, :diff_service, :commit_delta, request, timeout: GitalyClient.fast_timeout)
        response.flat_map { |msg| msg.deltas.to_ary }
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

        response = gitaly_client_call(@repository.storage, :commit_service, :tree_entry, request, timeout: GitalyClient.medium_timeout)

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

      def tree_entries(repository, revision, path, recursive, skip_flat_paths, pagination_params)
        unless pagination_params.nil? && recursive
          pagination_params ||= {}
          pagination_params[:limit] ||= TREE_ENTRIES_DEFAULT_LIMIT
        end

        request = Gitaly::GetTreeEntriesRequest.new(
          repository: @gitaly_repo,
          revision: encode_binary(revision),
          path: path.present? ? encode_binary(path) : '.',
          recursive: recursive,
          skip_flat_paths: skip_flat_paths,
          pagination_params: pagination_params
        )
        request.sort = Gitaly::GetTreeEntriesRequest::SortBy::TREES_FIRST if pagination_params

        response = gitaly_client_call(@repository.storage, :commit_service, :get_tree_entries, request, timeout: GitalyClient.medium_timeout)

        cursor = nil

        entries = response.flat_map do |message|
          cursor = message.pagination_cursor if message.pagination_cursor

          message.entries.map do |gitaly_tree_entry|
            Gitlab::Git::Tree.new(
              id: gitaly_tree_entry.oid,
              type: gitaly_tree_entry.type.downcase,
              mode: gitaly_tree_entry.mode.to_s(8),
              name: File.basename(gitaly_tree_entry.path),
              path: encode_binary(gitaly_tree_entry.path),
              flat_path: encode_binary(gitaly_tree_entry.flat_path),
              commit_id: gitaly_tree_entry.commit_oid
            )
          end
        end

        [entries, cursor]
      rescue GRPC::BadStatus => e
        detailed_error = GitalyClient.decode_detailed_error(e)

        case detailed_error.try(:error)
        when :path
          raise Gitlab::Git::Index::IndexError, path_error_message(detailed_error.path)
        when :resolve_tree
          raise Gitlab::Git::Index::IndexError, e.details
        else
          raise e
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

        gitaly_client_call(@repository.storage, :commit_service, :count_commits, request, timeout: GitalyClient.medium_timeout).count
      end

      def diverging_commit_count(from, to, max_count:)
        request = Gitaly::CountDivergingCommitsRequest.new(
          repository: @gitaly_repo,
          from: encode_binary(from),
          to: encode_binary(to),
          max_count: max_count
        )
        response = gitaly_client_call(@repository.storage, :commit_service, :count_diverging_commits, request, timeout: GitalyClient.medium_timeout)
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

        response = gitaly_client_call(@repository.storage, :commit_service, :list_last_commits_for_tree, request, timeout: GitalyClient.medium_timeout)

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

        gitaly_commit = gitaly_client_call(@repository.storage, :commit_service, :last_commit_for_path, request, timeout: GitalyClient.fast_timeout).commit
        return unless gitaly_commit

        Gitlab::Git::Commit.new(@repository, gitaly_commit)
      end

      def diff_stats(left_commit_sha, right_commit_sha)
        request = Gitaly::DiffStatsRequest.new(
          repository: @gitaly_repo,
          left_commit_id: left_commit_sha,
          right_commit_id: right_commit_sha
        )

        response = gitaly_client_call(@repository.storage, :diff_service, :diff_stats, request, timeout: GitalyClient.medium_timeout)
        response.flat_map { |rsp| rsp.stats.to_a }
      end

      # When finding changed paths and passing a sha for a merge commit we can
      # specify how to diff the commit.
      #
      # When diffing a merge commit and merge_commit_diff_mode is :all_parents
      # file paths are only returned if changed in both parents (or all parents
      # if diffing an octopus merge)
      #
      # This means if we create a merge request that includes a merge commit
      # of changes already existing in the target branch, we can omit those
      # changes when looking up the changed paths.
      #
      # e.g.
      #   1. User branches from master to new branch named feature/foo_bar
      #   2. User changes ./foo_bar.rb and commits change to feature/foo_bar
      #   3. Another user merges a change to ./bar_baz.rb to master
      #   4. User merges master into feature/foo_bar
      #   5. User pushes to GitLab
      #   6. GitLab checks which files have changed
      #
      # case merge_commit_diff_mode
      # when :all_parents
      #   ['foo_bar.rb']
      # when :include_merges
      #   ['foo_bar.rb', 'bar_baz.rb'],
      # else # defaults to :include_merges behavior
      #   ['foo_bar.rb', 'bar_baz.rb'],
      #
      def find_changed_paths(objects, merge_commit_diff_mode: nil, find_renames: false)
        request = find_changed_paths_request(objects, merge_commit_diff_mode, find_renames)

        return [] if request.nil?

        response = gitaly_client_call(@repository.storage, :diff_service, :find_changed_paths, request, timeout: GitalyClient.medium_timeout)
        response.flat_map do |msg|
          msg.paths.map do |path|
            Gitlab::Git::ChangedPath.new(
              status: path.status,
              path: EncodingHelper.encode!(path.path),
              old_path: EncodingHelper.encode!(path.old_path),
              old_mode: path.old_mode.to_s(8),
              new_mode: path.new_mode.to_s(8),
              old_blob_id: path.old_blob_id,
              new_blob_id: path.new_blob_id
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

        response = gitaly_client_call(@repository.storage, :commit_service, :find_all_commits, request, timeout: GitalyClient.medium_timeout)
        consume_commits_response(response)
      end

      def list_commits(revisions, params = {})
        # We want to include the commit ref in the revisions if present.
        revisions = Array.wrap(params[:ref].presence || []) + Array.wrap(revisions)

        request = Gitaly::ListCommitsRequest.new(
          repository: @gitaly_repo,
          revisions: revisions,
          reverse: !!params[:reverse],
          ignore_case: params[:ignore_case],
          pagination_params: params[:pagination_params]
        )

        request.order = params[:order].upcase if params[:order].present?
        request.skip = params[:skip].to_i if params[:skip].present?

        if params[:commit_message_patterns]
          request.commit_message_patterns += Array.wrap(params[:commit_message_patterns])
        end

        request.author = encode_binary(params[:author]) if params[:author]
        request.before = GitalyClient.timestamp(params[:before]) if params[:before]
        request.after = GitalyClient.timestamp(params[:after]) if params[:after]

        response = gitaly_client_call(
          @repository.storage,
          :commit_service,
          :list_commits,
          request,
          timeout: GitalyClient.medium_timeout
        )

        consume_commits_response(response)
      end

      # List all commits which are new in the repository. If commits have been pushed into the repo
      def list_new_commits(revisions)
        git_env = Gitlab::Git::HookEnv.all(@gitaly_repo.gl_repository)
        if git_env['GIT_OBJECT_DIRECTORY_RELATIVE'].present?
          # If we have a quarantine environment, then we can optimize the check
          # by doing a ListAllCommitsRequest. Instead of walking through
          # references, we just walk through all quarantined objects, which is
          # a lot more efficient. To do so, we throw away any alternate object
          # directories, which point to the main object directory of the
          # repository, and only keep the object directory which points into
          # the quarantine object directory.
          quarantined_repo = @gitaly_repo.dup
          quarantined_repo.git_alternate_object_directories = Google::Protobuf::RepeatedField.new(:string)

          request = Gitaly::ListAllCommitsRequest.new(
            repository: quarantined_repo
          )

          response = gitaly_client_call(@repository.storage, :commit_service, :list_all_commits, request, timeout: GitalyClient.medium_timeout)

          quarantined_commits = consume_commits_response(response)
          quarantined_commit_ids = quarantined_commits.map(&:id)

          # While in general the quarantine directory would only contain objects
          # which are actually new, this is not guaranteed by Git. In fact,
          # git-push(1) may sometimes push objects which already exist in the
          # target repository. We do not want to return those from this method
          # though given that they're not actually new.
          #
          # To fix this edge-case we thus have to filter commits down to those
          # which don't yet exist. To do so, we must check for object existence
          # in the main repository, but the object directory of our repository
          # points into the object quarantine. This can be fixed by unsetting
          # it, which will cause us to use the normal repository as indicated by
          # its relative path again.
          main_repo = @gitaly_repo.dup
          main_repo.git_object_directory = ""

          # Check object existence of all quarantined commits' IDs.
          quarantined_commit_existence = object_existence_map(quarantined_commit_ids, gitaly_repo: main_repo)

          # And then we reject all quarantined commits which exist in the main
          # repository already.
          quarantined_commits.reject! { |c| quarantined_commit_existence[c.id] }

          quarantined_commits
        else
          list_commits(Array.wrap(revisions) + %w[--not --all])
        end
      end

      def list_commits_by_oid(oids)
        return [] if oids.empty?

        request = Gitaly::ListCommitsByOidRequest.new(repository: @gitaly_repo, oid: oids)

        response = gitaly_client_call(@repository.storage, :commit_service, :list_commits_by_oid, request, timeout: GitalyClient.medium_timeout)
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

        response = gitaly_client_call(@repository.storage, :commit_service, :commits_by_message, request, timeout: GitalyClient.medium_timeout)
        consume_commits_response(response)
      end

      def languages(ref = nil)
        request = Gitaly::CommitLanguagesRequest.new(repository: @gitaly_repo, revision: ref || '')
        response = gitaly_client_call(@repository.storage, :commit_service, :commit_languages, request, timeout: GitalyClient.long_timeout)

        response.languages.map { |l| { value: l.share.round(2), label: l.name, color: l.color, highlight: l.color } }
      end

      def raw_blame(revision, path, range:, ignore_revisions_blob: nil)
        request = Gitaly::RawBlameRequest.new(
          repository: @gitaly_repo,
          revision: encode_binary(revision),
          path: encode_binary(path),
          range: (encode_binary(range) if range),
          ignore_revisions_blob: (encode_binary(ignore_revisions_blob) if ignore_revisions_blob)
        )

        response = gitaly_client_call(@repository.storage, :commit_service, :raw_blame, request, timeout: GitalyClient.medium_timeout)
        response.reduce([]) { |memo, msg| memo << msg.data }.join
      rescue GRPC::BadStatus => e
        detailed_error = GitalyClient.decode_detailed_error(e)

        case detailed_error.try(:error)
        when :out_of_range, :path_not_found
          raise ArgumentError, e.details
        else
          raise e
        end
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
        gitaly_client_call(@repository.storage, :commit_service, :commit_stats, request, timeout: GitalyClient.medium_timeout)
      end

      def find_commits(options)
        request = Gitaly::FindCommitsRequest.new(
          repository: @gitaly_repo,
          limit: options[:limit],
          offset: options[:offset],
          follow: options[:follow],
          skip_merges: options[:skip_merges],
          all: !!options[:all],
          first_parent: !!options[:first_parent],
          global_options: parse_global_options!(options),
          disable_walk: true, # This option is deprecated. The 'walk' implementation is being removed.
          trailers: options[:trailers],
          include_referenced_by: options[:include_referenced_by]
        )
        request.after    = GitalyClient.timestamp(options[:after]) if options[:after]
        request.before   = GitalyClient.timestamp(options[:before]) if options[:before]
        request.revision = encode_binary(options[:ref]) if options[:ref]
        request.author   = encode_binary(options[:author]) if options[:author]
        request.order    = options[:order].upcase.sub('DEFAULT', 'NONE') if options[:order].present?

        request.paths = encode_repeated(Array(options[:path])) if options[:path].present?

        response = gitaly_client_call(@repository.storage, :commit_service, :find_commits, request, timeout: GitalyClient.medium_timeout)
        consume_commits_response(response)
      end

      # Check whether the given revisions exist. Returns a hash mapping the revision name to either `true` if the
      # revision exists, or `false` otherwise. This function accepts all revisions as specified by
      # gitrevisions(1).
      def object_existence_map(revisions, gitaly_repo: @gitaly_repo)
        return {} unless revisions.present?

        enum = Enumerator.new do |y|
          revisions.each_slice(100).with_index do |revisions_subset, i|
            params = { revisions: revisions_subset }
            params[:repository] = gitaly_repo if i == 0

            y.yield Gitaly::CheckObjectsExistRequest.new(**params)
          end
        end

        response = gitaly_client_call(
          @repository.storage, :commit_service, :check_objects_exist, enum, timeout: GitalyClient.medium_timeout
        )

        existence_by_revision = {}
        response.each do |message|
          message.revisions.each do |revision|
            existence_by_revision[revision.name] = revision.exists
          end
        end

        existence_by_revision
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

        response = gitaly_client_call(@repository.storage, :commit_service, :filter_shas_with_signatures, enum, timeout: GitalyClient.fast_timeout)
        response.flat_map do |msg|
          msg.shas.map { |sha| EncodingHelper.encode!(sha) }
        end
      end

      def get_commit_signatures(commit_ids)
        request = Gitaly::GetCommitSignaturesRequest.new(repository: @gitaly_repo, commit_ids: commit_ids)
        response = gitaly_client_call(@repository.storage, :commit_service, :get_commit_signatures, request, timeout: GitalyClient.fast_timeout)

        signatures = Hash.new do |h, k|
          h[k] = {
            signature: +''.b,
            signed_text: +''.b,
            signer: :SIGNER_UNSPECIFIED,
            author_email: +''.b
          }
        end

        current_commit_id = nil

        response.each do |message|
          current_commit_id = message.commit_id if message.commit_id.present?

          signatures[current_commit_id][:signature] << message.signature
          signatures[current_commit_id][:signed_text] << message.signed_text
          signatures[current_commit_id][:author_email] << message.author.email if message.author.present?

          # The actual value is send once. All the other chunks send SIGNER_UNSPECIFIED
          signatures[current_commit_id][:signer] = message.signer unless message.signer == :SIGNER_UNSPECIFIED
        end

        signatures
      rescue GRPC::InvalidArgument => ex
        raise ArgumentError, ex
      end

      def get_commit_messages(commit_ids)
        request = Gitaly::GetCommitMessagesRequest.new(repository: @gitaly_repo, commit_ids: commit_ids)
        response = gitaly_client_call(@repository.storage, :commit_service, :get_commit_messages, request, timeout: GitalyClient.fast_timeout)

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

        response = gitaly_client_call(@repository.storage, :commit_service, :list_commits_by_ref_name, request, timeout: GitalyClient.medium_timeout)

        commit_refs = response.flat_map do |message|
          message.commit_refs.map do |commit_ref|
            [encode_utf8(commit_ref.ref_name), Gitlab::Git::Commit.new(@repository, commit_ref.commit)]
          end
        end

        Hash[commit_refs]
      end

      def get_patch_id(old_revision, new_revision)
        request = Gitaly::GetPatchIDRequest
          .new(repository: @gitaly_repo, old_revision: old_revision, new_revision: new_revision)

        response = gitaly_client_call(@repository.storage, :diff_service, :get_patch_id, request, timeout: GitalyClient.medium_timeout)

        response.patch_id
      end

      private

      def parse_global_options!(options)
        literal_pathspec = options.delete(:literal_pathspec)
        Gitaly::GlobalOptions.new(literal_pathspecs: literal_pathspec)
      end

      def call_commit_diff(request_params, options = {})
        if options.fetch(:ignore_whitespace_change, false)
          request_params[:whitespace_changes] = WHITESPACE_CHANGES['ignore_all_spaces']
        end

        request_params[:enforce_limits] = options.fetch(:limits, true)
        request_params[:collapse_diffs] = !options.fetch(:expanded, true)
        request_params.merge!(Gitlab::Git::DiffCollection.limits(options))

        request = Gitaly::CommitDiffRequest.new(request_params)
        response = gitaly_client_call(@repository.storage, :diff_service, :commit_diff, request, timeout: GitalyClient.medium_timeout)
        GitalyClient::DiffStitcher.new(response)
      end

      def diff_from_parent_request_params(commit, options = {})
        parent_id = commit.parent_ids.first || @repository.empty_tree_id

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
        Google::Protobuf::RepeatedField.new(:bytes, array.map { |s| encode_binary(s) })
      end

      def call_find_commit(revision)
        request = Gitaly::FindCommitRequest.new(
          repository: @gitaly_repo,
          revision: encode_binary(revision)
        )

        response = gitaly_client_call(@repository.storage, :commit_service, :find_commit, request, timeout: GitalyClient.medium_timeout)

        response.commit
      end

      def find_changed_paths_request(objects, merge_commit_diff_mode, find_renames)
        diff_mode = MERGE_COMMIT_DIFF_MODES[merge_commit_diff_mode]

        requests = objects.filter_map do |object|
          case object
          when Gitlab::Git::DiffTree
            Gitaly::FindChangedPathsRequest::Request.new(
              tree_request: Gitaly::FindChangedPathsRequest::Request::TreeRequest.new(left_tree_revision: object.left_tree_id, right_tree_revision: object.right_tree_id)
            )
          when Commit, Gitlab::Git::Commit
            next if object.sha.blank? || Gitlab::Git.blank_ref?(object.sha)

            Gitaly::FindChangedPathsRequest::Request.new(
              commit_request: Gitaly::FindChangedPathsRequest::Request::CommitRequest.new(commit_revision: object.sha)
            )
          end
        end

        return if requests.blank?

        Gitaly::FindChangedPathsRequest.new(repository: @gitaly_repo, requests: requests, merge_commit_diff_mode: diff_mode, find_renames: find_renames)
      end

      def path_error_message(path_error)
        case path_error.error_type
        when :ERROR_TYPE_EMPTY_PATH
          "You must provide a file path"
        when :ERROR_TYPE_RELATIVE_PATH_ESCAPES_REPOSITORY
          "Path cannot include traversal syntax"
        when :ERROR_TYPE_ABSOLUTE_PATH
          "Only relative path is accepted"
        when :ERROR_TYPE_LONG_PATH
          "Path is too long"
        else
          "Unknown path error"
        end
      end
    end
  end
end
