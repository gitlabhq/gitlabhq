# frozen_string_literal: true

# rubocop:disable Rails/Output
if Gitlab::Runtime.console?
  # note that this will not print out when using `spring`
  justify = 15

  puts '-' * 80
  puts " Ruby:".ljust(justify) + RUBY_DESCRIPTION
  puts " GitLab:".ljust(justify) + "#{Gitlab::VERSION} (#{Gitlab.revision}) #{Gitlab.ee? ? 'EE' : 'FOSS'}"
  puts " GitLab Shell:".ljust(justify) + "#{Gitlab::VersionInfo.parse(Gitlab::Shell.version)}"

  if Gitlab::Database.main.exists?
    puts " #{Gitlab::Database.main.human_adapter_name}:".ljust(justify) + Gitlab::Database.main.version

    Gitlab.ee do
      if Gitlab::Geo.connected? && Gitlab::Geo.enabled?
        puts " Geo enabled:".ljust(justify) + 'yes'
        puts " Geo server:".ljust(justify) + EE::GeoHelper.current_node_human_status
      end
    end
  end

  puts '-' * 80

  # Stop irb from writing a history file by default.
  module IrbNoHistory
    def init_config(*)
      super

      IRB.conf[:SAVE_HISTORY] = false
    end
  end

  IRB.singleton_class.prepend(IrbNoHistory)
end
