FactoryBot.define do
  factory :project_statistics do
    project

    initialize_with do
      # statistics are automatically created when a project is created
      project&.statistics || new
    end
  end
end
