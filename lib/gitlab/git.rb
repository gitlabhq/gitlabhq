module Gitlab
  module Git
    # '0' * 40 -- this was easyer to freeze
    BLANK_SHA = "0000000000000000000000000000000000000000".freeze
    TAG_REF_PREFIX = "refs/tags/".freeze
    BRANCH_REF_PREFIX = "refs/heads/".freeze

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

      def version
        Gitlab::VersionInfo.parse(Gitlab::Popen.popen(%W(#{Gitlab.config.git.bin_path} --version)).first)
      end
    end
  end
end
