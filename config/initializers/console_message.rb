# rubocop:disable Rails/Output
if defined?(Rails::Console)
  # note that this will not print out when using `spring`
  justify = 15
  puts "-------------------------------------------------------------------------------------"
  puts " GitLab:".ljust(justify) + "#{Gitlab::VERSION} (#{Gitlab.revision})"
  puts " GitLab Shell:".ljust(justify) + "#{Gitlab::VersionInfo.parse(Gitlab::Shell.new.version)}"
  puts " #{Gitlab::Database.human_adapter_name}:".ljust(justify) + Gitlab::Database.version

  # EE-specific start
  if Gitlab::Geo.enabled?
    puts " Geo enabled:".ljust(justify) + 'yes'
    puts " Geo server:".ljust(justify) + EE::GeoHelper.current_node_human_status
  end
  # EE specific end

  puts "-------------------------------------------------------------------------------------"
end
