# frozen_string_literal: true

class Gitlab::Seeder::ProjectFeatures
  include ActionView::Helpers::NumberHelper

  BATCH_SIZE = 100_000

  def seed!
    create_project_features!
  end

  def create_project_features!
    Gitlab::Seeder.with_mass_insert(Project.count, "Project features") do
      Project.each_batch(of: BATCH_SIZE) do |batch, index|
        range = batch.pluck(Arel.sql('MIN(id)'), Arel.sql('MAX(id)')).first
        count = index * batch.size

        Gitlab::Seeder.log_message("Creating project features: #{count}.")
        ActiveRecord::Base.connection.execute <<~SQL
          INSERT INTO project_features (project_id, merge_requests_access_level, issues_access_level, wiki_access_level, pages_access_level)
          SELECT
            id,
            #{ProjectFeature::ENABLED} AS merge_requests_access_level,
            #{ProjectFeature::ENABLED} AS issues_access_level,
            #{ProjectFeature::ENABLED} AS wiki_access_level,
            #{ProjectFeature::ENABLED} AS pages_access_level
          FROM projects 
          WHERE projects.id BETWEEN #{range.first} AND #{range.last}
          ON CONFLICT DO NOTHING;
        SQL
      end
    end
  end
end

Gitlab::Seeder.quiet do
  projects = Gitlab::Seeder::ProjectFeatures.new
  projects.seed!
end
