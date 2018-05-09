# This file contains environment settings for gitaly when it's running
# as part of the gitlab-ce/ee test suite.
# 
# Please be careful when modifying this file. Your changes must work
# both for local development rspec runs, and in CI.

require 'socket'

module GitalyTest
  def tmp_tests_gitaly_dir
    File.expand_path('../tmp/tests/gitaly', __dir__)
  end

  def gemfile
    File.join(tmp_tests_gitaly_dir, 'ruby', 'Gemfile')
  end

  def env
    env_hash = {
      'HOME' => File.expand_path('tmp/tests'),
      'GEM_PATH' => Gem.path.join(':'),
      'BUNDLE_APP_CONFIG' => File.join(File.dirname(gemfile), '.bundle/config'),
      'BUNDLE_FLAGS' => "--jobs=4 --retry=3",
      'BUNDLE_GEMFILE' => gemfile,
      'RUBYOPT' => nil
    }

    if ENV['CI']
      env_hash['BUNDLE_FLAGS'] << ' --deployment'
    end

    env_hash
  end

  def config_path
    File.join(tmp_tests_gitaly_dir, 'config.toml')
  end

  def spawn_gitaly
    args = %W[#{tmp_tests_gitaly_dir}/gitaly #{config_path}]
    spawn(env, *args, [:out, :err] => 'log/gitaly-test.log')
  end

  def check_gitaly_config!
    puts 'Checking gitaly-ruby bundle...'
    abort 'bundle check failed' unless system(env, 'bundle', 'check', chdir: File.dirname(gemfile))

    begin
      pid = spawn_gitaly
      try_connect!
    ensure
      Process.kill('TERM', pid)
    end
  end

  def read_socket_path
    # This is an external script because it needs bundler, we don't want to
    # poison the current process with 'bundle exec'.
    script = File.expand_path('gitaly-test-socket-path', __dir__)

    path = IO.popen(['bundle', 'exec', script, config_path], &:read).chomp
    raise "#{script} failed" unless $?.success?
    path
  end

  def try_connect!
    print "Trying to connect to gitaly: "
    timeout = 20
    delay = 0.1
    socket = read_socket_path

    Integer(timeout/delay).times do
      begin
        UNIXSocket.new(socket)
        puts ' OK'
  
        return
      rescue Errno::ENOENT
        print '.'
        sleep delay
      end
    end
  
    puts ' FAILED'
  
    raise "could not connect to #{socket}"
  end
end
