# frozen_string_literal: true

namespace :gitlab do
  namespace :js do
    desc "Make a js file with all rails route URL helpers"
    task routes: :environment do
      require 'gitlab/js_routes'

      Gitlab::JsRoutes.match_ci_env!('gitlab:js:routes')
      Gitlab::JsRoutes.generate!
    end

    namespace :routes do
      desc 'Check whether JavaScript path helpers are in sync with Rails routes, used during CI'
      task updated_check: :environment do
        require 'gitlab/js_routes'

        Gitlab::JsRoutes.match_ci_env!('gitlab:js:routes:updated_check')

        path_helper_dirs = Gitlab::JsRoutes::PATH_HELPERS_DIRS

        Gitlab::JsRoutes.generate!

        diff, = Gitlab::Popen.popen(['git', 'diff', '--', *path_helper_dirs])
        untracked, = Gitlab::Popen.popen(
          ['git', 'ls-files', '--others', '--exclude-standard', '--', *path_helper_dirs]
        )
        diff = diff.strip
        untracked = untracked.strip

        # Reset the path_helpers folders
        Gitlab::Popen.popen(['git', 'checkout', '--', *path_helper_dirs])
        Gitlab::Popen.popen(['git', 'clean', '-f', '--', *path_helper_dirs])

        if diff.present? || untracked.present?
          raise <<~MSG
            JavaScript path helpers are out of sync with Rails routes.

            If you added, removed, or modified a route, please regenerate the
            path helpers by running:

              bin/rake gitlab:js:routes

            Then commit the changes under:
              #{path_helper_dirs.join("\n  ")}

            Diff:
            #{diff}

            New (untracked) files:
            #{untracked}
          MSG
        end
      end
    end
  end
end
