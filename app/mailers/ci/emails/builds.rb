module Ci
  module Emails
    module Builds
      def build_fail_email(build_id, to)
        @build = Ci::Build.find(build_id)
        @project = @build.project
        mail(to: to, subject: subject("Build failed for #{@project.name}", @build.short_sha))
      end

      def build_success_email(build_id, to)
        @build = Ci::Build.find(build_id)
        @project = @build.project
        mail(to: to, subject: subject("Build success for #{@project.name}", @build.short_sha))
      end
    end
  end
end
