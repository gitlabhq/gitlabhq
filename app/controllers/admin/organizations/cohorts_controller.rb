# frozen_string_literal: true

module Admin
  module Organizations
    class CohortsController < Admin::Organizations::ApplicationController
      include Admin::CohortsActions

      def index
        @organization = ::Current.organization
        @cohorts = load_cohorts

        render 'admin/cohorts/index'
      end

      private

      def cohorts_organization
        ::Current.organization
      end
    end
  end
end
