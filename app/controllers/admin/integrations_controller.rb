# frozen_string_literal: true

class Admin::IntegrationsController < Admin::ApplicationController
  include ::Integrations::Actions
  include Admin::IntegrationsActions

  before_action :not_found, unless: -> { instance_level_integrations? }

  private

  def integrations_organization
    admin_current_organization
  end
end
