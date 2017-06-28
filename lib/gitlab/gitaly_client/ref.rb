module Gitlab
  module GitalyClient
    class Ref
      # 'repository' is a Gitlab::Git::Repository
      def initialize(repository)
        @gitaly_repo = repository.gitaly_repository
        @storage = repository.storage
      end

      def default_branch_name
        request = Gitaly::FindDefaultBranchNameRequest.new(repository: @gitaly_repo)
        response = GitalyClient.call(@storage, :ref, :find_default_branch_name, request)
        Gitlab::Git.branch_name(response.name)
      end

      def branch_names
        request = Gitaly::FindAllBranchNamesRequest.new(repository: @gitaly_repo)
        response = GitalyClient.call(@storage, :ref, :find_all_branch_names, request)
        consume_refs_response(response, prefix: 'refs/heads/')
      end

      def tag_names
        request = Gitaly::FindAllTagNamesRequest.new(repository: @gitaly_repo)
        response = GitalyClient.call(@storage, :ref, :find_all_tag_names, request)
        consume_refs_response(response, prefix: 'refs/tags/')
      end

      def find_ref_name(commit_id, ref_prefix)
        request = Gitaly::FindRefNameRequest.new(
          repository: @gitaly_repo,
          commit_id: commit_id,
          prefix: ref_prefix
        )
        GitalyClient.call(@storage, :ref, :find_ref_name, request).name
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
        response = GitalyClient.call(@storage, :ref, :find_local_branches, request)
        consume_branches_response(response)
      end

      private

      def consume_refs_response(response, prefix:)
        response.flat_map do |r|
          r.names.map { |name| name.sub(/\A#{Regexp.escape(prefix)}/, '') }
        end
      end

      def sort_by_param(sort_by)
        enum_value = Gitaly::FindLocalBranchesRequest::SortBy.resolve(sort_by.upcase.to_sym)
        raise ArgumentError, "Invalid sort_by key `#{sort_by}`" unless enum_value
        enum_value
      end

      def consume_branches_response(response)
        response.flat_map { |r| r.branches }
      end
    end
  end
end
