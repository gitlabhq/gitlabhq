module Gitlab
  module Git
    module Version
      extend Gitlab::Git::Popen

      def self.git_version
        Gitlab::VersionInfo.parse(popen(%W(#{Gitlab.config.git.bin_path} --version), nil).first)
      end
    end
  end
end
