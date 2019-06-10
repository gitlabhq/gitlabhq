# frozen_string_literal: true

module Emails
  module RemoteMirrors
    def remote_mirror_update_failed_email(remote_mirror_id, recipient_id)
      @remote_mirror = RemoteMirrorFinder.new(id: remote_mirror_id).execute
      @project = @remote_mirror.project

      mail(to: recipient(recipient_id, @project.group), subject: subject('Remote mirror update failed'))
    end
  end
end
