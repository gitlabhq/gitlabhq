FactoryGirl.define do
  factory :project_statistics do
    project { create :project }
    namespace { project.namespace }
  end
end
