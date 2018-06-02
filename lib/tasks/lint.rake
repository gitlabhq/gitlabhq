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
          rd_out, wr_out = IO.pipe
          rd_err, wr_err = IO.pipe
          stdout = $stdout.dup
          stderr = $stderr.dup
          $stdout.reopen(wr_out)
          $stderr.reopen(wr_err)

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
            wr_out.close
            wr_err.close

            warn "\n#{msg}\n\n" if msg

            IO.copy_stream(rd_out, $stdout)
            IO.copy_stream(rd_err, $stderr)
          end
        end

        Process.waitpid(pid)
        status += $?.exitstatus
      end

      exit(status)
    end
  end
end
