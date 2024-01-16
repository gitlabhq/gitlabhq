# frozen_string_literal: true

module Organizations
  class OrganizationsController < ApplicationController
    include PreviewMarkdown

    feature_category :cell

    skip_before_action :authenticate_user!, only: [:show, :groups_and_projects]

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

    def users
      authorize_read_organization_user!
    end
  end
end
