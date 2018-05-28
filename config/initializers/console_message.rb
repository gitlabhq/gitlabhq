# rubocop:disable Rails/Output
if defined?(Rails::Console)
  # note that this will not print out when using `spring`
  justify = 15
  puts "-------------------------------------------------------------------------------------"
  puts " Gitlab:".ljust(justify) + "#{Gitlab::VERSION} (#{Gitlab.revision})"
  puts " Gitlab Shell:".ljust(justify) + Gitlab::Shell.new.version
  puts " #{Gitlab::Database.adapter_name}:".ljust(justify) + Gitlab::Database.version
  puts "-------------------------------------------------------------------------------------"
end
