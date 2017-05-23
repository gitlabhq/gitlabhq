Gitlab::Seeder.quiet do
  conversational_development_index_metric = ConversationalDevelopmentIndexMetric.new(
    leader_issues: 10.2,
    instance_issues: 3.2,
    issues_level: 'low',

    leader_notes: 25.3,
    instance_notes: 23.2,
    notes_level: 'high',

    leader_milestones: 16.2,
    instance_milestones: 5.5,
    milestones_level: 'average',

    leader_boards: 5.2,
    instance_boards: 3.2,
    boards_level: 'average',

    leader_merge_requests: 5.2,
    instance_merge_requests: 3.2,
    merge_requests_level: 'average',

    leader_ci_pipelines: 25.1,
    instance_ci_pipelines: 21.3,
    ci_pipelines_level: 'high',

    leader_environments: 3.3,
    instance_environments: 2.2,
    environments_level: 'average',

    leader_deployments: 41.3,
    instance_deployments: 15.2,
    deployments_level: 'average',

    leader_projects_prometheus_active: 0.31,
    instance_projects_prometheus_active: 0.30,
    projects_prometheus_active_level: 'high',

    leader_service_desk_issues: 15.8,
    instance_service_desk_issues: 15.1,
    service_desk_issues_level: 'high'
  )

  if conversational_development_index_metric.save
    print '.'
  else
    puts conversational_development_index_metric.errors.full_messages
    print 'F'
  end
end
