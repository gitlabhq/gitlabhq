# rubocop:disable Rails/Output
if Gitlab::Runtime.console?
  # note that this will not print out when using `spring`
  justify = 15

  puts '-' * 80
  puts " GitLab:".ljust(justify) + "#{Gitlab::VERSION} (#{Gitlab.revision}) #{Gitlab.ee? ? 'EE' : 'FOSS'}"
  puts " GitLab Shell:".ljust(justify) + "#{Gitlab::VersionInfo.parse(Gitlab::Shell.version)}"

  if Gitlab::Database.exists?
    puts " #{Gitlab::Database.human_adapter_name}:".ljust(justify) + Gitlab::Database.version

    Gitlab.ee do
      if Gitlab::Geo.connected? && Gitlab::Geo.enabled?
        puts " Geo enabled:".ljust(justify) + 'yes'
        puts " Geo server:".ljust(justify) + EE::GeoHelper.current_node_human_status
      end
    end
  end

  puts '-' * 80
end
