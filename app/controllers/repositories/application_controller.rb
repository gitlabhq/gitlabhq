# frozen_string_literal: true

module Repositories
  class ApplicationController < ::ApplicationController
    skip_before_action :authenticate_user!

    # LFS enforces maintenance mode itself after the access checks (see
    # LfsRequest#check_organization_maintenance_mode!), so it responds with the
    # LFS content type and does not disclose the maintenance status to users
    # without access. The generic hook would run before those checks.
    skip_before_action :enforce_organization_maintenance_mode
  end
end
