FactoryBot.define do
  factory :project_ci_cd_setting do
    project

    initialize_with do
      # ci_cd_settings are automatically created when a project is created
      project&.ci_cd_settings || new
    end
  end
end
