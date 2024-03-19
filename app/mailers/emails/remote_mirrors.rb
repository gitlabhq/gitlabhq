# frozen_string_literal: true

module Emails
  module RemoteMirrors
    def remote_mirror_update_failed_email(remote_mirror_id, recipient_id)
      @remote_mirror = RemoteMirror.find_by_id(remote_mirror_id)
      @project = @remote_mirror.project
      @target_url = project_settings_repository_url(@project, anchor: 'js-mirror-settings')
      user = User.find(recipient_id)

      mail_with_locale(to: user.notification_email_for(@project.group), subject: subject('Remote mirror update failed'))
    end
  end
end
