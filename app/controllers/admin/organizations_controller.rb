# frozen_string_literal: true

module Admin
  class OrganizationsController < ApplicationController
    feature_category :cell

    before_action :check_feature_flag!

    def index; end

    private

    def check_feature_flag!
      access_denied! unless Feature.enabled?(:ui_for_organizations, current_user)
    end
  end
end
