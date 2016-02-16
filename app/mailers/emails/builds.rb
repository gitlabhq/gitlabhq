module Emails
  module Builds
    def build_fail_email(build_id, to)
      @build = Ci::Build.find(build_id)
      @project = @build.project

      add_project_headers
      add_build_headers('failed')
      mail(to: to, subject: subject("Build failed for #{@project.name}", @build.short_sha))
    end

    def build_success_email(build_id, to)
      @build = Ci::Build.find(build_id)
      @project = @build.project

      add_project_headers
      add_build_headers('success')
      mail(to: to, subject: subject("Build success for #{@project.name}", @build.short_sha))
    end

    private

    def add_build_headers(status)
      headers['X-GitLab-Build-Id'] = @build.id
      headers['X-GitLab-Build-Ref'] = @build.ref
      headers['X-GitLab-Build-Status'] = status.to_s
    end
  end
end
