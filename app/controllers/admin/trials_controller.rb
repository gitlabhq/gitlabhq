class Admin::TrialsController < Admin::ApplicationController
  before_action :check_presence_of_license

  def new
  end

  def create
    build_license

    if save_license
      redirect_to admin_license_url, notice: 'Your trial license was successfully activated'
    else
      message = 'An error occurred while generating the trial license, please try again a few minutes.<br>'\
        'If the error persist please try by creating the license from '\
        '<a href="https://about.gitlab.com/free-trial/" target="_blank">this page</a>.'

      flash.now[:alert] = message.html_safe
      render :new
    end
  end

  def build_license
    @license = License.new
  end

  def save_license
    result = HTTParty.post("#{Gitlab::SUBSCRIPTIONS_URL}/trials", body: params)

    if result.ok?
      @license.data = result['license_key']
      @license.save
    else
      Rails.logger.error("Error generating trial license: #{result['error']}")
      @license.errors.add(:base, result['error'])
    end

    @license.persisted?
  end

  def check_presence_of_license
    if error_message.present?
      redirect_to admin_license_url, alert: error_message
    end
  end

  private

  def error_message
    @message ||= if License.trial.present?
                   'You have already used a free trial, if you want to extend it please contact us at '\
                   '<a href="mailto:sales@gitlab.com">sales@gitlab.com</a>.'.html_safe
                 elsif License.current&.active?
                   'You already have an active license key installed on this server.'
                 end
  end
end
