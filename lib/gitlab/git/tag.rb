module Gitlab
  module Git
    class Tag < Ref
      attr_reader :object_sha

      def initialize(repository, name, target, message = nil)
        super(repository, name, target)

        @message = message
      end

      def message
        encode! @message
      end
    end
  end
end
