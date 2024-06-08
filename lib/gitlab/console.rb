# frozen_string_literal: true

# rubocop:disable Rails/Output
module Gitlab
  module Console
    class << self
      def welcome!
        return unless Gitlab::Runtime.console?

        # note that this will not print out when using `spring`
        justify = 15

        puts '-' * 80
        puts " Ruby:".ljust(justify) + RUBY_DESCRIPTION
        puts " GitLab:".ljust(justify) + "#{Gitlab::VERSION} (#{Gitlab.revision}) #{Gitlab.ee? ? 'EE' : 'FOSS'}"
        puts " GitLab Shell:".ljust(justify) + Gitlab::VersionInfo.parse(Gitlab::Shell.version).to_s

        if ApplicationRecord.database.exists?
          puts " #{ApplicationRecord.database.human_adapter_name}:".ljust(justify) + ApplicationRecord.database.version

          Gitlab.ee do
            if Gitlab::Geo.connected? && Gitlab::Geo.enabled?
              puts " Geo enabled:".ljust(justify) + 'yes'
              puts " Geo server:".ljust(justify) + EE::GeoHelper.current_node_human_status
            end
          end
        end

        if RUBY_PLATFORM.include?('darwin')
          # Sorry, macOS users. The current implementation requires procfs.
          puts '-' * 80
        else
          boot_time_seconds = Gitlab::Metrics::BootTimeTracker.instance.startup_time
          booted_in = "[ booted in %.2fs ]" % [boot_time_seconds]
          puts ('-' * (80 - booted_in.length)) + booted_in
        end
      end
    end
  end
end
# rubocop:enable Rails/Output
