# frozen_string_literal: true

module Gitlab
  module Git
    module Version
      def self.git_version
        Gitlab::VersionInfo.parse(Gitaly::Server.all.first.git_binary_version)
      end
    end
  end
end
