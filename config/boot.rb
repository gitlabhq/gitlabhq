def rails5?
  %w[1 true].include?(ENV["RAILS5"])
end

require 'rubygems' unless rails5?

gemfile = rails5? ? "Gemfile.rails5" : "Gemfile"
ENV['BUNDLE_GEMFILE'] ||= File.expand_path("../#{gemfile}", __dir__)

# Set up gems listed in the Gemfile.
require 'bundler/setup' if File.exist?(ENV['BUNDLE_GEMFILE'])
