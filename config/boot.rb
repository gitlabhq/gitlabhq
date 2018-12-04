def rails5?
  !%w[0 false].include?(ENV["RAILS5"])
end

require 'rubygems' unless rails5?

gemfile = rails5? ? "Gemfile" : "Gemfile.rails4"
ENV['BUNDLE_GEMFILE'] ||= File.expand_path("../#{gemfile}", __dir__)

# Set up gems listed in the Gemfile.
require 'bundler/setup' if File.exist?(ENV['BUNDLE_GEMFILE'])
begin
  require 'bootsnap/setup'
rescue LoadError
  # bootsnap is an optional dependency, so if we don't have it, it's fine
end
