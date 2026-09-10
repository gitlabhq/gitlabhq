# frozen_string_literal: true

module Admin
  module CohortsActions
    extend ActiveSupport::Concern

    included do
      feature_category :devops_reports

      urgency :low
    end

    private

    def load_cohorts
      cohorts_results = Rails.cache.fetch(cohorts_cache_key, expires_in: 1.day) do
        CohortsService.new(organization: cohorts_organization).execute
      end

      CohortsSerializer.new.represent(cohorts_results)
    end

    # The instance admin area aggregates all users, so cohorts are not scoped to
    # an organization. Overridden in the organization admin area.
    def cohorts_organization
      nil
    end

    def cohorts_cache_key
      organization = cohorts_organization

      return 'cohorts' unless organization

      "cohorts:organization:#{organization.id}"
    end
  end
end
