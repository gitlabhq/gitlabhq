module LicenseHelper
  # better text
  def license_message(signed_in: signed_in?, is_admin: (current_user && current_user.is_admin?))

    message = []

    license = License.current
    if license
      return unless signed_in

      return unless (license.notify_admins? && is_admin) || license.notify_users?

      message << "The GitLab Enterprise Edition license"
      message << (license.expired? ? "expired" : "will expire")
      message << "on #{license.expires_at}."

      if license.expired? && license.will_block_changes?
        message << "Pushing code and creation of issues and merge requests"

        if license.block_changes?
          message << "has been disabled."
        else
          message << "will be disabled on #{license.block_changes_at}."
        end
      end

      if is_admin
        message << "Upload a new license in the admin area"
      else
        message << "Ask an admin to upload a new license"
      end

      if license.block_changes?
        message << "to restore service."
      else
        message << "to ensure uninterrupted service."
      end
    else
      message << "No GitLab Enterprise Edition license has been provided yet."
      message << "Pushing code and creation of issues and merge requests has been disabled."

      if signed_in && is_admin
        message << "Upload a license in the admin area"
      else
        message << "Ask an admin to upload a license"
      end

      message << "to restore service."
    end

    message.join(" ")
  end

  extend self
end
