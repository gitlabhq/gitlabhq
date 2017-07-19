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
        encode!(GitalyClient.call(@storage, :ref_service, :find_ref_name, request).name.dup)
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
        consume_branches_response(response)
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

      def consume_branches_response(response)
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

        Gitlab::Git::Commit.decorate(hash)
      end
    end
  end
end
