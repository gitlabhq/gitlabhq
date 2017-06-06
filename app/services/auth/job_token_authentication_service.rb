module Auth
  class JobTokenAuthenticationService
    def execute(login = 'gitlab-ci-token', password)
      return unless login == 'gitlab-ci-token' && password.present?

      build = ::Ci::Build.running.find_by_token(password)
      return unless build&.project&.builds_enabled?

      if build.user
        # If user is assigned to build, use restricted credentials of user
        Gitlab::Auth::Result.new(build.user, build.project, :build)
      else
        # Otherwise use generic CI credentials (backward compatibility)
        Gitlab::Auth::Result.new(nil, build.project, :ci)
      end
    end
  end
end
