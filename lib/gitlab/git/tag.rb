module Gitlab
  module Git
    class Tag < Ref
      class << self
        def names_contains_sha(repo, sha)
          GitalyClient::RefService.new(repo).branch_names_contains_sha(sha)
        end
      end

      attr_reader :object_sha

      def initialize(repository, name, target, target_commit, message = nil)
        super(repository, name, target, target_commit)

        @message = message
      end

      def message
        encode! @message
      end
    end
  end
end
