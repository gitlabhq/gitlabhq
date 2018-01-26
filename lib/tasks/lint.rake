unless Rails.env.production?
  namespace :lint do
    task :static_verification_env do
      ENV['STATIC_VERIFICATION'] = 'true'
    end

    desc "GitLab | lint | Static verification"
    task static_verification: %w[
      lint:static_verification_env
      dev:load
    ] do
      Gitlab::Utils::Override.verify!
    end

    desc "GitLab | lint | Lint JavaScript files using ESLint"
    task :javascript do
      Rake::Task['eslint'].invoke
    end

    desc "GitLab | lint | Run several lint checks"
    task :all do
      status = 0
      original_stdout = $stdout

      %w[
        config_lint
        haml_lint
        scss_lint
        flay
        gettext:lint
        lint:static_verification
      ].each do |task|
        begin
          $stdout = StringIO.new
          Rake::Task[task].invoke
        rescue RuntimeError, SystemExit => ex
          raise ex if ex.is_a?(RuntimeError) && task != 'haml_lint'
          original_stdout << $stdout.string
          status = 1
        ensure
          $stdout = original_stdout
        end
      end

      exit status
    end
  end
end
