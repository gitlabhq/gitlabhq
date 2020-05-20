# frozen_string_literal: true

module API
  module Metrics
    class UserStarredDashboards < Grape::API
      resource :projects do
        desc 'Marks selected metrics dashboard as starred' do
          success Entities::Metrics::UserStarredDashboard
        end

        params do
          requires :dashboard_path, type: String, allow_blank: false, coerce_with: ->(val) { CGI.unescape(val) },
                   desc: 'Url encoded path to a file defining the dashboard to which the star should be added'
        end

        post ':id/metrics/user_starred_dashboards' do
          result = ::Metrics::UsersStarredDashboards::CreateService.new(current_user, user_project, params[:dashboard_path]).execute

          if result.success?
            present result.payload, with: Entities::Metrics::UserStarredDashboard
          else
            error!({ errors: result.message }, 400)
          end
        end

        desc 'Remove star from selected metrics dashboard'

        params do
          optional :dashboard_path, type: String, allow_blank: false, coerce_with: ->(val) { CGI.unescape(val) },
                   desc: 'Url encoded path to a file defining the dashboard from which the star should be removed'
        end

        delete ':id/metrics/user_starred_dashboards' do
          result = ::Metrics::UsersStarredDashboards::DeleteService.new(current_user, user_project, params[:dashboard_path]).execute

          if result.success?
            status :ok
            result.payload
          else
            status :bad_request
          end
        end
      end
    end
  end
end
