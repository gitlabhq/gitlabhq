# frozen_string_literal: true

module StartupCssHelper
  def use_startup_css?
    (Feature.enabled?(:startup_css) || params[:startup_css] == 'true' || cookies['startup_css'] == 'true') && !Rails.env.test?
  end
end
