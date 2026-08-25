# frozen_string_literal: true

module Admin
  class OrganizationsController < ApplicationController
    include ::Organizations::OrganizationHelper

    feature_category :organization

    before_action :check_feature_flag!

    def index; end

    private

    def check_feature_flag!
      access_denied! unless ui_for_organizations_enabled?
    end
  end
end
