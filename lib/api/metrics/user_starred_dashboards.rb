# frozen_string_literal: true

module API
  module Metrics
    class UserStarredDashboards < ::API::Base
      feature_category :metrics
      urgency :low

      USER_STARRED_DASHBOARDS_TAGS = %w[user_starred_dashboards].freeze

      resource :projects do
        desc 'Add a star to a dashboard' do
          detail 'Marks selected metrics dashboard as starred. Introduced in GitLab 13.0.'
          success Entities::Metrics::UserStarredDashboard
          failure [
            { code: 400, message: 'Bad request' },
            { code: 404, message: 'Not found' }
          ]
          tags USER_STARRED_DASHBOARDS_TAGS
        end

        params do
          requires :dashboard_path, type: String, allow_blank: false, coerce_with: ->(val) { CGI.unescape(val) },
                                    desc: 'URL-encoded path to file defining the dashboard which should be marked as favorite'
        end

        post ':id/metrics/user_starred_dashboards' do
          not_found!
        end

        desc 'Remove a star from a dashboard' do
          detail 'Remove star from selected metrics dashboard. Introduced in GitLab 13.0.'
          success code: 200
          failure [
            { code: 400, message: 'Bad request' },
            { code: 404, message: 'Not found' }
          ]
          tags USER_STARRED_DASHBOARDS_TAGS
        end

        params do
          optional :dashboard_path, type: String, allow_blank: false, coerce_with: ->(val) { CGI.unescape(val) },
                                    desc: 'Url encoded path to a file defining the dashboard from which the star should be removed'
        end

        delete ':id/metrics/user_starred_dashboards' do
          not_found!
        end
      end
    end
  end
end
