module Gitlab
  module Git
    BLANK_SHA = '0' * 40
    TAG_REF_PREFIX = "refs/tags/"
    BRANCH_REF_PREFIX = "refs/heads/"

    class << self
      def ref_name(ref)
        ref.gsub(/\Arefs\/(tags|heads)\//, '')
      end

      def tag_ref?(ref)
        ref.start_with?(TAG_REF_PREFIX)
      end

      def branch_ref?(ref)
        ref.start_with?(BRANCH_REF_PREFIX)
      end

      def blank_ref?(ref)
        ref == BLANK_SHA
      end
    end
  end
end
