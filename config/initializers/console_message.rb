# rubocop:disable Rails/Output
if defined?(Rails::Console)
  # note that this will not print out when using `spring`
  justify = 15

  puts '-' * 80
  puts " GitLab:".ljust(justify) + "#{Gitlab::VERSION} (#{Gitlab.revision})"
  puts " GitLab Shell:".ljust(justify) + "#{Gitlab::VersionInfo.parse(Gitlab::Shell.new.version)}"
  puts " #{Gitlab::Database.human_adapter_name}:".ljust(justify) + Gitlab::Database.version

  Gitlab.ee do
    if Gitlab::Geo.enabled?
      puts " Geo enabled:".ljust(justify) + 'yes'
      puts " Geo server:".ljust(justify) + EE::GeoHelper.current_node_human_status
    end
  end

  puts '-' * 80
end
