class GenerateProjectFeatureForProjects < ActiveRecord::Migration
  DOWNTIME = true

  DOWNTIME_REASON = <<-HEREDOC
    Application was eager loading project_feature for all projects generating an extra query
    everytime a project was fetched. We removed that behavior to avoid the extra query, this migration
    makes sure all projects have a project_feature record associated.
  HEREDOC

  def up
    # Generate enabled values for each project feature 20, 20, 20, 20, 20
    # All features are enabled by default
    enabled_values = [ProjectFeature::ENABLED] * 5

    execute <<-EOF.strip_heredoc
      INSERT INTO project_features
      (project_id, merge_requests_access_level, builds_access_level,
      issues_access_level, snippets_access_level, wiki_access_level)
      (SELECT projects.id, #{enabled_values.join(',')} FROM projects LEFT OUTER JOIN project_features
      ON project_features.project_id = projects.id
      WHERE project_features.id IS NULL)
    EOF
  end

  def down
    "Not needed"
  end
end
