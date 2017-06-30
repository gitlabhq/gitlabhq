module Gitlab
  module GitalyClient
    class Ref
      include Gitlab::EncodingHelper

      attr_accessor :stub

      # 'repository' is a Gitlab::Git::Repository
      def initialize(repository)
        @repository = repository
        @gitaly_repo = repository.gitaly_repository
        @stub = GitalyClient.stub(:ref, repository.storage)
      end

      def default_branch_name
        request = Gitaly::FindDefaultBranchNameRequest.new(repository: @gitaly_repo)
        branch_name = stub.find_default_branch_name(request).name

        Gitlab::Git.branch_name(branch_name)
      end

      def branch_names
        request = Gitaly::FindAllBranchNamesRequest.new(repository: @gitaly_repo)
        consume_refs_response(stub.find_all_branch_names(request)) { |name| Gitlab::Git.branch_name(name) }
      end

      def tag_names
        request = Gitaly::FindAllTagNamesRequest.new(repository: @gitaly_repo)
        consume_refs_response(stub.find_all_tag_names(request)) { |name| Gitlab::Git.tag_name(name) }
      end

      def find_ref_name(commit_id, ref_prefix)
        request = Gitaly::FindRefNameRequest.new(
          repository: @gitaly_repo,
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

      def consume_refs_response(response)
        response.flat_map { |message| message.names.map { |name| yield(name) } }
      end

      def sort_by_param(sort_by)
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
              gitaly_branch.commit_id
            )
          end
        end
      end
    end
  end
end
