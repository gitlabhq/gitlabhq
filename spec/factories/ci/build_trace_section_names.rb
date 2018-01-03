FactoryBot.define do
  factory :ci_build_trace_section_name, class: Ci::BuildTraceSectionName do
    sequence(:name) { |n| "section_#{n}" }
    project factory: :project
  end
end
