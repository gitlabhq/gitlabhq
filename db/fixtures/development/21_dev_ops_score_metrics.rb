Gitlab::Seeder.quiet do
  dev_ops_score_metric = DevOpsScore::Metric.new(
    leader_issues: 10.2,
    instance_issues: 3.2,

    leader_notes: 25.3,
    instance_notes: 23.2,

    leader_milestones: 16.2,
    instance_milestones: 5.5,

    leader_boards: 5.2,
    instance_boards: 3.2,

    leader_merge_requests: 5.2,
    instance_merge_requests: 3.2,

    leader_ci_pipelines: 25.1,
    instance_ci_pipelines: 21.3,

    leader_environments: 3.3,
    instance_environments: 2.2,

    leader_deployments: 41.3,
    instance_deployments: 15.2,

    leader_projects_prometheus_active: 0.31,
    instance_projects_prometheus_active: 0.30,

    leader_service_desk_issues: 15.8,
    instance_service_desk_issues: 15.1
  )

  if dev_ops_score_metric.save
    print '.'
  else
    puts dev_ops_score_metric.errors.full_messages
    print 'F'
  end
end
