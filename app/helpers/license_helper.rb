module LicenseHelper
  include ActionView::Helpers::AssetTagHelper
  include ActionView::Helpers::UrlHelper

  delegate :new_admin_license_path, to: 'Gitlab::Routing.url_helpers'

  def current_active_user_count
    User.active.count
  end

  def max_historical_user_count
    HistoricalData.max_historical_user_count
  end

  # in_html is set to false from an initializer, which shouldn't try to render
  # HTML links.
  #
  def license_message(signed_in: signed_in?, is_admin: (current_user && current_user.admin?), in_html: true)
    @license_message =
      if License.current
        yes_license_message(signed_in, is_admin)
      else
        no_license_message(is_admin, in_html: in_html)
      end
  end

  private

  def no_license_message(is_admin, in_html: true)
    upload_a_license =
      if in_html
        link_to('Upload a license', new_admin_license_path)
      else
        'Upload a license'
      end

    message = []
    message << 'No GitLab Enterprise Edition license has been provided yet.'
    message << 'Pushing code and creation of issues and merge requests has been disabled.'
    message <<
      if is_admin
        "#{upload_a_license} in the admin area to activate this functionality."
      else
        'Ask an admin to upload a license to activate this functionality.'
      end

    if in_html
      content_tag(:p, message.join(' ').html_safe)
    else
      message.join(' ')
    end
  end

  def yes_license_message(signed_in, is_admin)
    license = License.current

    return unless signed_in

    return unless (is_admin && license.notify_admins?) || license.notify_users?

    message = []

    message << 'The GitLab Enterprise Edition license'
    message << (license.expired? ? 'expired' : 'will expire')
    message << "on #{license.expires_at}."

    if license.expired? && license.will_block_changes?
      message << 'Pushing code and creation of issues and merge requests'

      message <<
        if license.block_changes?
          'has been disabled.'
        else
          "will be disabled on #{license.block_changes_at}."
        end

      message <<
        if is_admin
          'Upload a new license in the admin area'
        else
          'Ask an admin to upload a new license'
        end

      message << 'to'
      message << (license.block_changes? ? 'restore' : 'ensure uninterrupted')
      message << 'service.'
    end

    message.join(' ')
  end

  extend self
end
