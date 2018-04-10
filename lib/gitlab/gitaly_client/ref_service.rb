module Gitlab
  module GitalyClient
    class RefService
      include Gitlab::EncodingHelper

      # 'repository' is a Gitlab::Git::Repository
      def initialize(repository)
        @repository = repository
        @gitaly_repo = repository.gitaly_repository
        @storage = repository.storage
      end

      def branches
        request = Gitaly::FindAllBranchesRequest.new(repository: @gitaly_repo)
        response = GitalyClient.call(@storage, :ref_service, :find_all_branches, request)

        consume_find_all_branches_response(response)
      end

      def merged_branches(branch_names = [])
        request = Gitaly::FindAllBranchesRequest.new(
          repository: @gitaly_repo,
          merged_only: true,
          merged_branches: branch_names.map { |s| encode_binary(s) }
        )
        response = GitalyClient.call(@storage, :ref_service, :find_all_branches, request)

        consume_find_all_branches_response(response)
      end

      def default_branch_name
        request = Gitaly::FindDefaultBranchNameRequest.new(repository: @gitaly_repo)
        response = GitalyClient.call(@storage, :ref_service, :find_default_branch_name, request)
        Gitlab::Git.branch_name(response.name)
      end

      def branch_names
        request = Gitaly::FindAllBranchNamesRequest.new(repository: @gitaly_repo)
        response = GitalyClient.call(@storage, :ref_service, :find_all_branch_names, request)
        consume_refs_response(response) { |name| Gitlab::Git.branch_name(name) }
      end

      def tag_names
        request = Gitaly::FindAllTagNamesRequest.new(repository: @gitaly_repo)
        response = GitalyClient.call(@storage, :ref_service, :find_all_tag_names, request)
        consume_refs_response(response) { |name| Gitlab::Git.tag_name(name) }
      end

      def find_ref_name(commit_id, ref_prefix)
        request = Gitaly::FindRefNameRequest.new(
          repository: @gitaly_repo,
          commit_id: commit_id,
          prefix: ref_prefix
        )
        response = GitalyClient.call(@storage, :ref_service, :find_ref_name, request, timeout: GitalyClient.medium_timeout)
        encode!(response.name.dup)
      end

      def count_tag_names
        tag_names.count
      end

      def count_branch_names
        branch_names.count
      end

      def local_branches(sort_by: nil)
        request = Gitaly::FindLocalBranchesRequest.new(repository: @gitaly_repo)
        request.sort_by = sort_by_param(sort_by) if sort_by
        response = GitalyClient.call(@storage, :ref_service, :find_local_branches, request)
        consume_find_local_branches_response(response)
      end

      def tags
        request = Gitaly::FindAllTagsRequest.new(repository: @gitaly_repo)
        response = GitalyClient.call(@storage, :ref_service, :find_all_tags, request)
        consume_tags_response(response)
      end

      def ref_exists?(ref_name)
        request = Gitaly::RefExistsRequest.new(repository: @gitaly_repo, ref: encode_binary(ref_name))
        response = GitalyClient.call(@storage, :ref_service, :ref_exists, request)
        response.value
      rescue GRPC::InvalidArgument => e
        raise ArgumentError, e.message
      end

      def find_branch(branch_name)
        request = Gitaly::FindBranchRequest.new(
          repository: @gitaly_repo,
          name: encode_binary(branch_name)
        )

        response = GitalyClient.call(@repository.storage, :ref_service, :find_branch, request)
        branch = response.branch
        return unless branch

        target_commit = Gitlab::Git::Commit.decorate(@repository, branch.target_commit)
        Gitlab::Git::Branch.new(@repository, encode!(branch.name.dup), branch.target_commit.id, target_commit)
      end

      def create_branch(ref, start_point)
        request = Gitaly::CreateBranchRequest.new(
          repository: @gitaly_repo,
          name: encode_binary(ref),
          start_point: encode_binary(start_point)
        )

        response = GitalyClient.call(@repository.storage, :ref_service, :create_branch, request)

        case response.status
        when :OK
          branch = response.branch
          target_commit = Gitlab::Git::Commit.decorate(@repository, branch.target_commit)
          Gitlab::Git::Branch.new(@repository, branch.name, branch.target_commit.id, target_commit)
        when :ERR_INVALID
          invalid_ref!("Invalid ref name")
        when :ERR_EXISTS
          invalid_ref!("Branch #{ref} already exists")
        when :ERR_INVALID_START_POINT
          invalid_ref!("Invalid reference #{start_point}")
        else
          raise "Unknown response status: #{response.status}"
        end
      end

      def delete_branch(branch_name)
        request = Gitaly::DeleteBranchRequest.new(
          repository: @gitaly_repo,
          name: encode_binary(branch_name)
        )

        GitalyClient.call(@repository.storage, :ref_service, :delete_branch, request)
      end

      def delete_refs(refs: [], except_with_prefixes: [])
        request = Gitaly::DeleteRefsRequest.new(
          repository: @gitaly_repo,
          refs: refs.map { |r| encode_binary(r) },
          except_with_prefix: except_with_prefixes.map { |r| encode_binary(r) }
        )

        response = GitalyClient.call(@repository.storage, :ref_service, :delete_refs, request)

        raise Gitlab::Git::Repository::GitError, response.git_error if response.git_error.present?
      end

      # Limit: 0 implies no limit, thus all tag names will be returned
      def tag_names_contains_sha(sha, limit: 0)
        request = Gitaly::ListTagNamesContainingCommitRequest.new(
          repository: @gitaly_repo,
          commit_id: sha,
          limit: limit
        )

        stream = GitalyClient.call(@repository.storage, :ref_service, :list_tag_names_containing_commit, request)

        consume_ref_contains_sha_response(stream, :tag_names)
      end

      # Limit: 0 implies no limit, thus all tag names will be returned
      def branch_names_contains_sha(sha, limit: 0)
        request = Gitaly::ListBranchNamesContainingCommitRequest.new(
          repository: @gitaly_repo,
          commit_id: sha,
          limit: limit
        )

        stream = GitalyClient.call(@repository.storage, :ref_service, :list_branch_names_containing_commit, request)

        consume_ref_contains_sha_response(stream, :branch_names)
      end

      private

      def consume_refs_response(response)
        response.flat_map { |message| message.names.map { |name| yield(name) } }
      end

      def sort_by_param(sort_by)
        sort_by = 'name' if sort_by == 'name_asc'

        enum_value = Gitaly::FindLocalBranchesRequest::SortBy.resolve(sort_by.upcase.to_sym)
        raise ArgumentError, "Invalid sort_by key `#{sort_by}`" unless enum_value

        enum_value
      end

      def consume_find_local_branches_response(response)
        response.flat_map do |message|
          message.branches.map do |gitaly_branch|
            Gitlab::Git::Branch.new(
              @repository,
              encode!(gitaly_branch.name.dup),
              gitaly_branch.commit_id,
              commit_from_local_branches_response(gitaly_branch)
            )
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

      def consume_tags_response(response)
        response.flat_map do |message|
          message.tags.map { |gitaly_tag| Util.gitlab_tag_from_gitaly_tag(@repository, gitaly_tag) }
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
        raise Gitlab::Git::Repository::InvalidRef.new(message)
      end
    end
  end
end
