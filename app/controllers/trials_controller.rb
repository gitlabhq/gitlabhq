class TrialsController < ApplicationController
  SUBSCRIPTIONS_PORTAL_URL = 'https://customers.gitlab.com'

  before_filter :check_presence_of_license

  def new
  end

  def create
    build_license

    if save_license
      redirect_to admin_license_url
    else
      flash.now[:alert] = 'An error occurred while generating the trial license, please try again a few minutes'
      render :new
    end
  end

  private

  def build_license
    @license = License.new
  end

  def save_license
    result = HTTParty.post("#{SUBSCRIPTIONS_PORTAL_URL}/trials", body: params)

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
    current_license = License.current

    if current_license && !current_license.expired?
      redirect_to admin_license_url
    end
  end
end
