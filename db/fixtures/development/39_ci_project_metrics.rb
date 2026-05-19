Gitlab::Seeder.quiet do
  Project.limit(10).each do |project|
    Ci::ProjectMetric.upsert(
      { project_id: project.id, created_at: Time.current, updated_at: Time.current },
      unique_by: :project_id
    )
    print '.'
  end
end
