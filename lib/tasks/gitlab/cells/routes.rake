# frozen_string_literal: true

namespace :gitlab do
  namespace :cells do
    namespace :routes do
      output_path = 'config/routing/gitlab_routes.json'

      # Match CI's invocation context before the route table is drawn. Routes
      # depend on the Rails environment (development and test each mount their
      # own), on CI (config/environments/test.rb skips the Sprockets `/assets`
      # mount when it is set), and on Settings (the `/users/auth` callbacks are
      # drawn from the omniauth providers in gitlab.yml), so the output is only
      # deterministic when we match what CI sees.
      #
      # Re-exec instead of assigning ENV here: Rails.env is memoized when the
      # Rakefile loads the application, before the task body runs.
      match_ci_env = ->(task_name) do
        if %w[true 1].include?(ENV['FOSS_ONLY'].to_s)
          abort "#{task_name} cannot run with FOSS_ONLY=#{ENV['FOSS_ONLY']}; EE routes would be missing."
        end

        return if ENV['CI']
        return if Rails.env.test? && ENV['GITLAB_CONFIG'].to_s.end_with?('config/gitlab.yml.example')

        exec(
          {
            'RAILS_ENV' => 'test',
            'CI' => 'true',
            'GITLAB_CONFIG' => Rails.root.join('config/gitlab.yml.example').to_s
          },
          'bin/rake', task_name
        )
      end

      # Collecting the route table is the only part that needs a booted
      # application; the snapshot itself is built by the gem. Returns the
      # snapshot so callers can report on what was written.
      write_snapshot = ->(task_name) do
        match_ci_env.call(task_name)
        Rake::Task['environment'].invoke

        require 'gitlab/cells/http_router'

        snapshot = Gitlab::Cells::HttpRouter::RoutesSnapshot.new(
          path_specs: Rails.application.routes.routes.map { |route| route.path.spec.to_s } +
            API::API.routes.map { |route| route.path.to_s }
        )
        snapshot.write!(Rails.root.join(output_path))

        snapshot
      end

      desc 'GitLab | Cells | Generate the routing snapshot consumed by the HTTP Router'
      task :generate do
        snapshot = write_snapshot.call('gitlab:cells:routes:generate')

        puts "Generated #{snapshot.routes.size} routes at #{Rails.root.join(output_path)}"
      end

      desc 'GitLab | Cells | Check whether the routing snapshot is in sync with Rails routes, used during CI'
      task :updated_check do
        write_snapshot.call('gitlab:cells:routes:updated_check')

        diff, = Gitlab::Popen.popen(['git', 'diff', '--', output_path])
        # Also check for an untracked file: if the snapshot was deleted, `git diff`
        # sees nothing and the regenerated copy would pass unnoticed.
        untracked, = Gitlab::Popen.popen(['git', 'ls-files', '--others', '--exclude-standard', '--', output_path])
        diff = diff.strip
        untracked = untracked.strip

        # The regenerated file is left in place on purpose: the CI job exposes it
        # as an artifact so the author can download the correct copy.
        next if diff.blank? && untracked.blank?

        raise <<~MSG
          #{output_path} is out of date.

          A route was added, changed, or removed without refreshing the HTTP Router snapshot.
          Regenerate it and commit the result:

            bundle exec rake gitlab:cells:routes:generate

          If the diff below is unrelated to your changes, a route landed on master after
          you last generated the snapshot. This job runs on the merged result, so
          regenerating locally will report no change until you rebase:

            git fetch origin master && git rebase origin/master

          Diff:
          #{diff}

          New (untracked) files:
          #{untracked}
        MSG
      end
    end
  end
end
