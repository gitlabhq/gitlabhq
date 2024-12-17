# frozen_string_literal: true

module Gitlab
  module GitalyClient
    class RefService
      include Gitlab::EncodingHelper
      include WithFeatureFlagActors

      TAGS_SORT_KEY = {
        'name' => Gitaly::FindAllTagsRequest::SortBy::Key::REFNAME,
        'updated' => Gitaly::FindAllTagsRequest::SortBy::Key::CREATORDATE,
        'version' => Gitaly::FindAllTagsRequest::SortBy::Key::VERSION_REFNAME
      }.freeze

      TAGS_SORT_DIRECTION = {
        'asc' => Gitaly::SortDirection::ASCENDING,
        'desc' => Gitaly::SortDirection::DESCENDING
      }.freeze

      AMBIGUOUS_REFERENCE = 'reference is ambiguous'

      # 'repository' is a Gitlab::Git::Repository
      def initialize(repository)
        @repository = repository
        @gitaly_repo = repository.gitaly_repository
        @storage = repository.storage

        self.repository_actor = repository
      end

      def branches
        request = Gitaly::FindAllBranchesRequest.new(repository: @gitaly_repo)
        response = gitaly_client_call(@storage, :ref_service, :find_all_branches, request, timeout: GitalyClient.fast_timeout)
        consume_find_all_branches_response(response)
      end

      def remote_branches(remote_name)
        request = Gitaly::FindAllRemoteBranchesRequest.new(repository: @gitaly_repo, remote_name: remote_name)
        response = gitaly_client_call(@storage, :ref_service, :find_all_remote_branches, request, timeout: GitalyClient.medium_timeout)
        consume_find_all_remote_branches_response(remote_name, response)
      end

      def merged_branches(branch_names = [])
        request = Gitaly::FindAllBranchesRequest.new(
          repository: @gitaly_repo,
          merged_only: true,
          merged_branches: branch_names.map { |s| encode_binary(s) }
        )
        response = gitaly_client_call(@storage, :ref_service, :find_all_branches, request, timeout: GitalyClient.fast_timeout)
        consume_find_all_branches_response(response)
      end

      def default_branch_name(head_only: false)
        request = Gitaly::FindDefaultBranchNameRequest.new(repository: @gitaly_repo, head_only: head_only)
        response = gitaly_client_call(@storage, :ref_service, :find_default_branch_name, request, timeout: GitalyClient.fast_timeout)
        Gitlab::Git.branch_name(response.name)
      end

      def local_branches(sort_by: nil, pagination_params: nil)
        request = Gitaly::FindLocalBranchesRequest.new(repository: @gitaly_repo, pagination_params: pagination_params)
        request.sort_by = sort_local_branches_by_param(sort_by) if sort_by
        response = gitaly_client_call(@storage, :ref_service, :find_local_branches, request, timeout: GitalyClient.fast_timeout)
        consume_find_local_branches_response(response)
      end

      def tags(sort_by: nil, pagination_params: nil)
        request = Gitaly::FindAllTagsRequest.new(repository: @gitaly_repo, pagination_params: pagination_params)
        request.sort_by = sort_tags_by_param(sort_by) if sort_by

        response = gitaly_client_call(@storage, :ref_service, :find_all_tags, request, timeout: GitalyClient.medium_timeout)
        consume_tags_response(response)
      end

      def ref_exists?(ref_name)
        request = Gitaly::RefExistsRequest.new(repository: @gitaly_repo, ref: encode_binary(ref_name))
        response = gitaly_client_call(@storage, :ref_service, :ref_exists, request, timeout: GitalyClient.fast_timeout)
        response.value
      rescue GRPC::InvalidArgument => e
        raise ArgumentError, e.message
      end

      def find_branch(branch_name)
        request = Gitaly::FindBranchRequest.new(
          repository: @gitaly_repo,
          name: encode_binary(branch_name)
        )

        response = gitaly_client_call(@repository.storage, :ref_service, :find_branch, request, timeout: GitalyClient.medium_timeout)
        branch = response.branch
        return unless branch

        target_commit = Gitlab::Git::Commit.decorate(@repository, branch.target_commit)
        Gitlab::Git::Branch.new(@repository, branch.name.dup, branch.target_commit.id, target_commit)
      rescue GRPC::BadStatus => e
        raise e unless e.message.include?(AMBIGUOUS_REFERENCE)

        raise Gitlab::Git::AmbiguousRef, "branch is ambiguous: #{branch_name}"
      end

      def find_tag(tag_name)
        return if tag_name.blank?

        request = Gitaly::FindTagRequest.new(
          repository: @gitaly_repo,
          tag_name: encode_binary(tag_name)
        )

        response = gitaly_client_call(@repository.storage, :ref_service, :find_tag, request, timeout: GitalyClient.medium_timeout)
        tag = response.tag
        return unless tag

        Gitlab::Git::Tag.new(@repository, tag)
      rescue GRPC::BadStatus => e
        detailed_error = GitalyClient.decode_detailed_error(e)

        case detailed_error.try(:error)
        when :tag_not_found
          raise Gitlab::Git::ReferenceNotFoundError, "tag does not exist: #{tag_name}"
        else
          # When this is not a know structured error we simply re-raise the exception.
          raise e
        end
      end

      def update_refs(ref_list:)
        request = Enumerator.new do |y|
          ref_list.each_slice(100) do |refs|
            updates = refs.map do |ref_pair|
              Gitaly::UpdateReferencesRequest::Update.new(
                old_object_id: ref_pair[:old_sha],
                new_object_id: ref_pair[:new_sha],
                reference: encode_binary(ref_pair[:reference])
              )
            end

            y.yield Gitaly::UpdateReferencesRequest.new(repository: @gitaly_repo, updates: updates)
          end
        end

        gitaly_client_call(@repository.storage, :ref_service, :update_references, request, timeout: GitalyClient.long_timeout)
      rescue GRPC::BadStatus => e
        detailed_error = GitalyClient.decode_detailed_error(e)

        case detailed_error.try(:error)
        when :invalid_format
          raise Gitlab::Git::InvalidRefFormatError, "references have an invalid format: #{detailed_error.invalid_format.refs.join(',')}"
        when :references_locked
          raise Gitlab::Git::ReferencesLockedError
        when :reference_state_mismatch
          raise Gitlab::Git::ReferenceStateMismatchError
        else
          raise e
        end
      end

      def delete_refs(refs: [], except_with_prefixes: [])
        request = Gitaly::DeleteRefsRequest.new(
          repository: @gitaly_repo,
          refs: refs.map { |r| encode_binary(r) },
          except_with_prefix: except_with_prefixes.map { |r| encode_binary(r) }
        )

        response = gitaly_client_call(@repository.storage, :ref_service, :delete_refs, request, timeout: GitalyClient.medium_timeout)

        raise Gitlab::Git::Repository::GitError, response.git_error if response.git_error.present?
      rescue GRPC::BadStatus => e
        detailed_error = GitalyClient.decode_detailed_error(e)

        case detailed_error.try(:error)
        when :invalid_format
          raise Gitlab::Git::InvalidRefFormatError, "references have an invalid format: #{detailed_error.invalid_format.refs.join(',')}"
        when :references_locked
          raise Gitlab::Git::ReferencesLockedError
        else
          raise e
        end
      end

      # Limit: 0 implies no limit, thus all tag names will be returned
      def tag_names_contains_sha(sha, limit: 0)
        request = Gitaly::ListTagNamesContainingCommitRequest.new(
          repository: @gitaly_repo,
          commit_id: sha,
          limit: limit
        )

        response = gitaly_client_call(@storage, :ref_service, :list_tag_names_containing_commit, request, timeout: GitalyClient.medium_timeout)
        consume_ref_contains_sha_response(response, :tag_names)
      end

      # Limit: 0 implies no limit, thus all tag names will be returned
      def branch_names_contains_sha(sha, limit: 0)
        request = Gitaly::ListBranchNamesContainingCommitRequest.new(
          repository: @gitaly_repo,
          commit_id: sha,
          limit: limit
        )

        response = gitaly_client_call(@storage, :ref_service, :list_branch_names_containing_commit, request, timeout: GitalyClient.medium_timeout)
        consume_ref_contains_sha_response(response, :branch_names)
      end

      def get_tag_messages(tag_ids)
        request = Gitaly::GetTagMessagesRequest.new(repository: @gitaly_repo, tag_ids: tag_ids)
        messages = Hash.new { |h, k| h[k] = +''.b }
        current_tag_id = nil

        response = gitaly_client_call(@storage, :ref_service, :get_tag_messages, request, timeout: GitalyClient.fast_timeout)
        response.each do |rpc_message|
          current_tag_id = rpc_message.tag_id if rpc_message.tag_id.present?

          messages[current_tag_id] << rpc_message.message
        end

        messages
      end

      def get_tag_signatures(tag_ids)
        request = Gitaly::GetTagSignaturesRequest.new(repository: @gitaly_repo, tag_revisions: tag_ids)
        response = gitaly_client_call(@repository.storage, :ref_service, :get_tag_signatures, request, timeout: GitalyClient.fast_timeout)

        signatures = Hash.new { |h, k| h[k] = [+''.b, +''.b] }
        current_tag_id = nil

        response.each do |message|
          message.signatures.each do |tag_signature|
            current_tag_id = tag_signature.tag_id if tag_signature.tag_id.present?

            signatures[current_tag_id].first << tag_signature.signature
            signatures[current_tag_id].last << tag_signature.content
          end
        end

        signatures
      rescue GRPC::InvalidArgument => ex
        raise ArgumentError, ex
      end

      # peel_tags slows down the request by a factor of 3-4
      def list_refs(patterns = [Gitlab::Git::BRANCH_REF_PREFIX], pointing_at_oids: [], peel_tags: false, dynamic_timeout: nil)
        request = Gitaly::ListRefsRequest.new(
          repository: @gitaly_repo,
          patterns: patterns,
          pointing_at_oids: pointing_at_oids,
          peel_tags: peel_tags
        )

        timeout = dynamic_timeout || GitalyClient.fast_timeout

        response = gitaly_client_call(@storage, :ref_service, :list_refs, request, timeout: timeout)
        consume_list_refs_response(response)
      end

      def find_refs_by_oid(oid:, limit:, ref_patterns: nil)
        request = Gitaly::FindRefsByOIDRequest.new(repository: @gitaly_repo, sort_field: :refname, oid: oid, limit: limit, ref_patterns: ref_patterns)

        response = gitaly_client_call(@storage, :ref_service, :find_refs_by_oid, request, timeout: GitalyClient.medium_timeout)
        response&.refs&.to_a
      end

      private

      def consume_refs_response(response)
        response.flat_map { |message| message.names.map { |name| yield(name) } }
      end

      def consume_list_refs_response(response)
        response.flat_map { |res| res.references.to_ary }
      end

      def sort_local_branches_by_param(sort_by)
        sort_by = 'name' if sort_by == 'name_asc'

        enum_value = Gitaly::FindLocalBranchesRequest::SortBy.resolve(sort_by.upcase.to_sym)
        return Gitaly::FindLocalBranchesRequest::SortBy::NAME unless enum_value

        enum_value
      end

      def sort_tags_by_param(sort_by)
        match = sort_by.match(/^(?<key>name|updated|version)_(?<direction>asc|desc)$/)

        return unless match

        Gitaly::FindAllTagsRequest::SortBy.new(
          key: TAGS_SORT_KEY[match[:key]],
          direction: TAGS_SORT_DIRECTION[match[:direction]]
        )
      end

      def consume_find_local_branches_response(response)
        response.flat_map do |message|
          if message.local_branches.present?
            message.local_branches.map do |branch|
              target_commit = Gitlab::Git::Commit.decorate(@repository, branch.target_commit)
              Gitlab::Git::Branch.new(@repository, branch.name, branch.target_commit.id, target_commit)
            end
          else
            message.branches.map do |gitaly_branch|
              Gitlab::Git::Branch.new(
                @repository,
                gitaly_branch.name.dup,
                gitaly_branch.commit_id,
                commit_from_local_branches_response(gitaly_branch)
              )
            end
          end
        end
      end

      def consume_find_all_branches_response(response)
        response.flat_map do |message|
          message.branches.map do |branch|
            target_commit = Gitlab::Git::Commit.decorate(@repository, branch.target)
            Gitlab::Git::Branch.new(@repository, branch.name, branch.target.id, target_commit)
          end
        end
      end

      def consume_find_all_remote_branches_response(remote_name, response)
        remote_name += '/' unless remote_name.ends_with?('/')

        response.flat_map do |message|
          message.branches.map do |branch|
            target_commit = Gitlab::Git::Commit.decorate(@repository, branch.target_commit)
            branch_name = branch.name.sub(remote_name, '')
            Gitlab::Git::Branch.new(@repository, branch_name, branch.target_commit.id, target_commit)
          end
        end
      end

      def consume_tags_response(response)
        response.flat_map do |message|
          message.tags.map { |gitaly_tag| Gitlab::Git::Tag.new(@repository, gitaly_tag) }
        end
      end

      def commit_from_local_branches_response(response)
        # Git messages have no encoding enforcements. However, in the UI we only
        # handle UTF-8, so basically we cross our fingers that the message force
        # encoded to UTF-8 is readable.
        message = response.commit_subject.dup.force_encoding('UTF-8')

        # NOTE: For ease of parsing in Gitaly, we have only the subject of
        # the commit and not the full message. This is ok, since all the
        # code that uses `local_branches` only cares at most about the
        # commit message.
        # TODO: Once gitaly "takes over" Rugged consider separating the
        # subject from the message to make it clearer when there's one
        # available but not the other.
        hash = {
          id: response.commit_id,
          message: message,
          authored_date: Time.at(response.commit_author.date.seconds),
          author_name: response.commit_author.name.dup,
          author_email: response.commit_author.email.dup,
          committed_date: Time.at(response.commit_committer.date.seconds),
          committer_name: response.commit_committer.name.dup,
          committer_email: response.commit_committer.email.dup
        }

        Gitlab::Git::Commit.decorate(@repository, hash)
      end

      def consume_ref_contains_sha_response(stream, collection_name)
        stream.each_with_object([]) do |response, array|
          encoded_names = response.send(collection_name).map { |b| Gitlab::Git.ref_name(b) } # rubocop:disable GitlabSecurity/PublicSend
          array.concat(encoded_names)
        end
      end

      def invalid_ref!(message)
        raise Gitlab::Git::Repository::InvalidRef, message
      end
    end
  end
end
