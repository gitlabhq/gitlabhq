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

  def license_message(signed_in: signed_in?, is_admin: current_user&.admin?)
    return unless current_license
    return unless signed_in
    return unless (is_admin && current_license.notify_admins?) || current_license.notify_users?

    is_trial = current_license.trial?
    message = ["Your Enterprise Edition #{'trial ' if is_trial}license"]

    message << if current_license.expired?
                 "expired on #{current_license.expires_at}."
               else
                 "will expire in #{pluralize(current_license.remaining_days, 'day')}."
               end

    message << link_to('Buy now!', Gitlab::SUBSCRIPTIONS_PLANS_URL, target: '_blank') if is_trial

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

    message.join(' ').html_safe
  end

  def current_license
    return @current_license if defined?(@current_license)

    @current_license = License.current
  end

  extend self
end
