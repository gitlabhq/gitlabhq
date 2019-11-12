# frozen_string_literal: true

module Emails
  module Releases
    def new_release_email(user_id, release, reason = nil)
      @release = release
      @project = @release.project
      @target_url = namespace_project_releases_url(
        namespace_id: @project.namespace,
        project_id: @project
      )

      user = User.find(user_id)

      mail(
        to: user.notification_email_for(@project.group),
        subject: subject(release_email_subject)
      )
    end

    private

    def release_email_subject
      release_info =
        if @release.name == @release.tag
          @release.tag
        else
          [@release.name, @release.tag].select(&:presence).join(' - ')
        end

      "New release: #{release_info}"
    end
  end
end
