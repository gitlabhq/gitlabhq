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

      %w[
        config_lint
        haml_lint
        scss_lint
        flay
        gettext:lint
        lint:static_verification
      ].each do |task|
        pid = Process.fork do
          rd, wr = IO.pipe
          stdout = $stdout.dup
          stderr = $stderr.dup
          $stdout.reopen(wr)
          $stderr.reopen(wr)

          begin
            begin
              Rake::Task[task].invoke
            rescue RuntimeError # The haml_lint tasks raise a RuntimeError
              exit(1)
            end
          rescue SystemExit => ex
            msg = "*** Rake task #{task} failed with the following error(s):"
            raise ex
          ensure
            $stdout.reopen(stdout)
            $stderr.reopen(stderr)
            wr.close

            if msg
              warn "\n#{msg}\n\n"
              IO.copy_stream(rd, $stderr)
            else
              IO.copy_stream(rd, $stdout)
            end
          end
        end

        Process.waitpid(pid)
        status += $?.exitstatus
      end

      exit(status)
    end
  end
end
