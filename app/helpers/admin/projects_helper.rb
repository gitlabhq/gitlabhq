# frozen_string_literal: true

module Admin
  module ProjectsHelper
    def admin_projects_app_data
      {
        programming_languages: programming_languages
      }.to_json
    end
  end
end
