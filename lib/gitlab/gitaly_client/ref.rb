module Gitlab
  module GitalyClient
    class Ref
      attr_accessor :stub

      # 'repository' is a Gitlab::Git::Repository
      def initialize(repository)
        @gitaly_repo = repository.gitaly_repository
        @stub = Gitaly::Ref::Stub.new(nil, nil, channel_override: repository.gitaly_channel)
      end

      def default_branch_name
        request = Gitaly::FindDefaultBranchNameRequest.new(repository: @gitaly_repo)
        branch_name = stub.find_default_branch_name(request).name

        Gitlab::Git.branch_name(branch_name)
      end

      def branch_names
        request = Gitaly::FindAllBranchNamesRequest.new(repository: @gitaly_repo)
        consume_refs_response(stub.find_all_branch_names(request), prefix: 'refs/heads/')
      end

      def tag_names
        request = Gitaly::FindAllTagNamesRequest.new(repository: @gitaly_repo)
        consume_refs_response(stub.find_all_tag_names(request), prefix: 'refs/tags/')
      end

      def find_ref_name(commit_id, ref_prefix)
        request = Gitaly::FindRefNameRequest.new(
          repository: @repository,
          commit_id: commit_id,
          prefix: ref_prefix
        )

        stub.find_ref_name(request).name
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
        consume_branches_response(stub.find_local_branches(request))
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
