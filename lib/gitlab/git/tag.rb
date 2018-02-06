module Gitlab
  module Git
    class Tag < Ref
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
