ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../Gemfile', __dir__)

# Set up gems listed in the Gemfile.
require 'bundler/setup' if File.exist?(ENV['BUNDLE_GEMFILE'])
begin
  require 'bootsnap/setup' unless ENV['DISABLE_BOOTSNAP']
rescue LoadError
  # bootsnap is an optional dependency, so if we don't have it, it's fine
end
