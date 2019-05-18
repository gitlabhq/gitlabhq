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

    desc "GitLab | lint | Lint HAML files"
    task :haml do
      Rake::Task['haml_lint'].invoke
    rescue RuntimeError # The haml_lint tasks raise a RuntimeError
      exit(1)
    end

    desc "GitLab | lint | Run several lint checks"
    task :all do
      status = 0

      %w[
        config_lint
        lint:haml
        scss_lint
        gettext:lint
        gettext:updated_check
        lint:static_verification
      ].each do |task|
        pid = Process.fork do
          puts "*** Running rake task: #{task} ***"

          Rake::Task[task].invoke
        rescue SystemExit => ex
          warn "!!! Rake task #{task} exited:"
          raise ex
        rescue StandardError, ScriptError => ex
          warn "!!! Rake task #{task} raised #{ex.class}:"
          raise ex
        end

        Process.waitpid(pid)
        status += $?.exitstatus
      end

      exit(status)
    end
  end
end
