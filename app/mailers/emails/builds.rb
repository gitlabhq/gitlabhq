module Emails
  module Builds
    def build_fail_email(build_id, to)
      @build = Ci::Build.find(build_id)
      @project = @build.project

      add_project_headers
      add_build_headers('failed')
      mail(to: to, subject: subject("项目 #{@project.name} 构建失败", @build.short_sha))
    end

    def build_success_email(build_id, to)
      @build = Ci::Build.find(build_id)
      @project = @build.project

      add_project_headers
      add_build_headers('success')
      mail(to: to, subject: subject("项目 #{@project.name} 构建成功", @build.short_sha))
    end

    private

    def add_build_headers(status)
      headers['X-GitLab-Build-Id'] = @build.id
      headers['X-GitLab-Build-Ref'] = @build.ref
      headers['X-GitLab-Build-Status'] = status.to_s
    end
  end
end
