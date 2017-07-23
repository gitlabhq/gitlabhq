FactoryGirl.define do
  factory :conversational_development_index_metric, class: ConversationalDevelopmentIndex::Metric do
    leader_issues 9.256
    instance_issues 1.234

    leader_notes 30.33333
    instance_notes 28.123

    leader_milestones 16.2456
    instance_milestones 1.234

    leader_boards 5.2123
    instance_boards 3.254

    leader_merge_requests 1.2
    instance_merge_requests 0.6

    leader_ci_pipelines 12.1234
    instance_ci_pipelines 2.344

    leader_environments 3.3333
    instance_environments 2.2222

    leader_deployments 1.200
    instance_deployments 0.771

    leader_projects_prometheus_active 0.111
    instance_projects_prometheus_active 0.109

    leader_service_desk_issues 15.891
    instance_service_desk_issues 13.345
  end
end
