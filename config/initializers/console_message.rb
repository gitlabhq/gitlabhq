# rubocop:disable Rails/Output
if defined?(Rails::Console)
  # note that this will not print out when using `spring`
  justify = 15
  puts "-------------------------------------------------------------------------------------"
  puts " GitLab:".ljust(justify) + "#{Gitlab::VERSION} (#{Gitlab.revision})"
  puts " GitLab Shell:".ljust(justify) + "#{Gitlab::VersionInfo.parse(Gitlab::Shell.new.version)}"
  puts " #{Gitlab::Database.adapter_name}:".ljust(justify) + Gitlab::Database.version

  # EE-specific start
  if Gitlab::Geo.enabled?
    puts " Geo enabled:".ljust(justify) + 'yes'
    puts " Geo server:".ljust(justify) + (Gitlab::Geo.primary? ? 'primary' : 'secondary')
  end

  # EE specific end

  puts "-------------------------------------------------------------------------------------"
end
