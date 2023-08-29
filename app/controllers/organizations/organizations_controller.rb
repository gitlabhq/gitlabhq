# frozen_string_literal: true

module Organizations
  class OrganizationsController < ApplicationController
    feature_category :cell

    skip_before_action :authenticate_user!, except: [:index, :new]

    def index; end

    def new
      authorize_create_organization!
    end

    def show
      authorize_read_organization!
    end

    def groups_and_projects
      authorize_read_organization!
    end
  end
end
