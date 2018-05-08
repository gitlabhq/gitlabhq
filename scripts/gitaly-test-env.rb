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
      'BUNDLE_IGNORE_CONFIG' => 'true',
      'BUNDLE_APP_CONFIG' => nil,
      'BUNDLE_FLAGS' => "--jobs=4 --retry=3",
      'BUNDLE_GEMFILE' => gemfile,
      'RUBYOPT' => nil
    }

    env_hash
  end

  def args
    %W[#{tmp_tests_gitaly_dir}/gitaly #{tmp_tests_gitaly_dir}/config.toml]
  end

  def check_gitaly_config!
    abort 'bundle check failed' unless system(env, 'bundle', 'check', chdir: File.dirname(gemfile))

    abort 'config load failed' unless system(env, args[0], '-test-config', *args[1, args.length])
  end
end
