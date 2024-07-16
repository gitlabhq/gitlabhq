# frozen_string_literal: true

%w[
  .ruby-version
  .rbenv-vars
  tmp/restart.txt
  tmp/caching-dev.txt
].each { |path| Spring.watch(path) }

Spring.after_fork do
  if ENV['DEBUGGER_STORED_RUBYLIB']
    ENV['DEBUGGER_STORED_RUBYLIB'].split(File::PATH_SEPARATOR).each do |path|
      next unless path.include?('ruby-debug-ide')

      load "#{path}/ruby-debug-ide/multiprocess/starter.rb"
    end
  end

  # Reset RSpec's seed unless is passed as argument.
  # Inspired by https://github.com/rails/spring/issues/113#issuecomment-427162116
  if Rails.env.test?
    RSpec.configure do |config|
      config.seed = rand(0xFFFF) unless ARGV.any?('--seed')
    end
  end
end
