if ENV['MY_RUBY_HOME'] && ENV['MY_RUBY_HOME'].include?('rvm')
  begin
    rvm_path     = File.dirname(File.dirname(ENV['MY_RUBY_HOME']))
    rvm_lib_path = File.join(rvm_path, 'lib')
    $LOAD_PATH.unshift rvm_lib_path
    require 'rvm'
    RVM.use_from_path! File.dirname(File.dirname(__FILE__))
  rescue LoadError
    # RVM is unavailable at this point.
    raise "RVM ruby lib is currently unavailable."
  end
end

# Select the correct item for which you use below.
# If you're not using bundler, remove it completely.

# If we're using a Bundler 1.0 beta
ENV['BUNDLE_GEMFILE'] = File.expand_path('../Gemfile', File.dirname(__FILE__))
require 'bundler/setup'

# Or Bundler 0.9...
if File.exist?(".bundle/environment.rb")
  require '.bundle/environment'
else
  require 'rubygems'
  require 'bundler'
  Bundler.setup
end
