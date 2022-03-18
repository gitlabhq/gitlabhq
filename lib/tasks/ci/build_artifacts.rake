# frozen_string_literal: true

require 'httparty'
require 'csv'

namespace :ci do
  namespace :build_artifacts do
    desc "GitLab | CI | Fetch projects with incorrect artifact size on GitLab.com"
    task :project_with_incorrect_artifact_size do
      csv_url = ENV['SISENSE_PROJECT_IDS_WITH_INCORRECT_ARTIFACTS_URL']

      # rubocop: disable Gitlab/HTTParty
      body = HTTParty.get(csv_url)
      # rubocop: enable Gitlab/HTTParty

      table = CSV.parse(body.parsed_response, headers: true)
      puts table['PROJECT_ID'].join(' ')
    end
  end
end
