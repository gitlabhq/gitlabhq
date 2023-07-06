# frozen_string_literal: true

module Organizations
  class OrganizationsController < ApplicationController
    feature_category :cell

    before_action { authorize_action!(:admin_organization) }

    def show; end

    def groups_and_projects; end
  end
end
