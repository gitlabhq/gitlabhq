module SystemCheck
  module Geo
    class GitVersionCheck < ::SystemCheck::App::GitVersionCheck
      set_name -> { "Git version >= #{self.required_version} ?" }
      set_check_pass -> { "yes (#{self.current_version})" }

      def self.required_version
        @required_version ||= Gitlab::VersionInfo.new(2, 9, 5)
      end
    end
  end
end
