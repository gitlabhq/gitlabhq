# frozen_string_literal: true

class HealthCheckController < HealthCheck::HealthCheckController
  helper ViteHelper

  include RequiresAllowlistedMonitoringClient

  before_action do
    # rubocop:disable Rails/StrongParams -- only mapping values for the param
    next if params[:checks].blank?

    params[:checks] = params[:checks].split('_').map! do |check|
      # Map the `migrations` check to the custom `all-migrations` check defined in
      # https://gitlab.com/gitlab-org/gitlab/-/blob/e8be888b786b28644ad9279abba1a801a07af0e3/config/initializers/health_check.rb#L11-18
      next 'all-migrations' if check == 'migrations'

      check
    end.join('_')
    # rubocop:enable Rails/StrongParams
  end
end
