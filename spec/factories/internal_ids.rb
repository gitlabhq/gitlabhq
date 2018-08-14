FactoryBot.define do
  factory :internal_id do
    project
    usage :issues
    last_value { project.issues.maximum(:iid) || 0 }
  end
end
