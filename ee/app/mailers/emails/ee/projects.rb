module Emails
  module EE
    module Projects
      def mirror_was_hard_failed_email(project_id, user_id)
        @project = Project.find(project_id)
        user = User.find(user_id)

        mail(to: user.notification_email,
             subject: subject('Repository mirroring paused'))
      end

      def project_mirror_user_changed_email(new_mirror_user_id, deleted_user_name, project_id)
        @project = Project.find(project_id)
        @deleted_user_name = deleted_user_name
        new_mirror_user = User.find(new_mirror_user_id)

        mail(to: new_mirror_user.notification_email,
             subject: subject('Mirror user changed'))
      end
    end
  end
end
