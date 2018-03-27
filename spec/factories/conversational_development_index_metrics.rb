FactoryBot.define do
  factory :conversational_development_index_metric, class: ConversationalDevelopmentIndex::Metric do
    leader_issues 9.256
    instance_issues 1.234
    percentage_issues 13.331

    leader_notes 30.33333
    instance_notes 28.123
    percentage_notes 92.713

    leader_milestones 16.2456
    instance_milestones 1.234
    percentage_milestones 7.595

    leader_boards 5.2123
    instance_boards 3.254
    percentage_boards 62.429

    leader_merge_requests 1.2
    instance_merge_requests 0.6
    percentage_merge_requests 50.0

    leader_ci_pipelines 12.1234
    instance_ci_pipelines 2.344
    percentage_ci_pipelines 19.334

    leader_environments 3.3333
    instance_environments 2.2222
    percentage_environments 66.672

    leader_deployments 1.200
    instance_deployments 0.771
    percentage_deployments 64.25

    leader_projects_prometheus_active 0.111
    instance_projects_prometheus_active 0.109
    percentage_projects_prometheus_active 98.198

    leader_service_desk_issues 15.891
    instance_service_desk_issues 13.345
    percentage_service_desk_issues 83.978
  end
end
