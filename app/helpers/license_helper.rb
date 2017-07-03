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

  def license_message(signed_in: signed_in?, is_admin: (current_user && current_user.admin?))
    yes_license_message(signed_in, is_admin) if current_license
  end

  def trial_license_message
    return unless signed_in? && current_license&.trial?
    return unless 7.days.since(Date.today) >= current_license.expires_at

    buy_now_link = link_to('Buy now!', "#{Gitlab::SUBSCRIPTIONS_URL}/plans", target: '_blank')
    message =
      if current_license.expired?
        if current_user.admin?
          "Your GitLab Enterprise Edition trial license expired. #{buy_now_link}".html_safe
        else
          "Your GitLab Enterprise Edition trial license expired. Please contact your administrator."
        end
      elsif current_user.admin?
        remaining_days = (current_license.expires_at - Date.today).to_i

        "Your GitLab Enterprise Edition trial license will expire in #{pluralize(remaining_days, 'day')}. #{buy_now_link}".html_safe
      end

    message
  end

  private

  def current_license
    return @current_license if defined?(@current_license)

    @current_license = License.current
  end

  def yes_license_message(signed_in, is_admin)
    return if current_license.trial?
    return unless signed_in
    return unless (is_admin && current_license.notify_admins?) || current_license.notify_users?

    message = []

    message << 'The GitLab Enterprise Edition license'
    message << (current_license.expired? ? 'expired' : 'will expire')
    message << "on #{current_license.expires_at}."

    if current_license.expired? && current_license.will_block_changes?
      message << 'Pushing code and creation of issues and merge requests'

      message <<
        if current_license.block_changes?
          'has been disabled.'
        else
          "will be disabled on #{current_license.block_changes_at}."
        end

      message <<
        if is_admin
          'Upload a new license in the admin area'
        else
          'Ask an admin to upload a new license'
        end

      message << 'to'
      message << (current_license.block_changes? ? 'restore' : 'ensure uninterrupted')
      message << 'service.'
    end

    message.join(' ')
  end

  extend self
end
