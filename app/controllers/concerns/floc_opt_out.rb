# frozen_string_literal: true

module FlocOptOut
  extend ActiveSupport::Concern

  included do
    after_action :set_floc_opt_out_header, unless: :floc_enabled?
  end

  def floc_enabled?
    Gitlab::CurrentSettings.floc_enabled
  end

  def set_floc_opt_out_header
    response.headers['Permissions-Policy'] = 'interest-cohort=()'
  end
end
