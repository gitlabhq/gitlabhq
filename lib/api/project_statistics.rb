# frozen_string_literal: true

module API
  class ProjectStatistics < ::API::Base
    feature_category :source_code_management

    before do
      authenticate!
      authorize! :daily_statistics, user_project
    end

    params do
      requires :id, types: [String, Integer], desc: 'The ID or URL-encoded path of the project'
    end
    resource :projects, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
      desc 'Get the list of project fetch statistics for the last 30 days' do
        success Entities::ProjectDailyStatistics
        failure [
          { code: 404, message: '404 Project Not Found' },
          { code: 401, message: '401 Unauthorized' }
        ]
        tags %w[projects]
      end

      get ":id/statistics" do
        statistic_finder = ::Projects::DailyStatisticsFinder.new(user_project)

        present statistic_finder, with: Entities::ProjectDailyStatistics
      end
    end
  end
end
