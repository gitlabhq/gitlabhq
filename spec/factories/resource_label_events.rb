FactoryBot.define do
  factory :resource_label_event do
    user { issue.project.creator }
    action :add
    label
    issue
  end
end
