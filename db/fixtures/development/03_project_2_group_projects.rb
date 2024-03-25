# frozen_string_literal: true

require './db/fixtures/development/03_project'

class Gitlab::Seeder::GroupProjects
  def seed!
    create_projects!
  end

  private

  def create_projects!
    groups = Namespace.where("path LIKE ?", "#{Gitlab::Seeder::MASS_INSERT_PREFIX}%").where(type: 'Group')

    Gitlab::Seeder.with_mass_insert(groups.count * Gitlab::Seeder::Projects.projects_per_user_count, "Projects and corresponding project namespaces") do
      groups.each_batch(of: Gitlab::Seeder::Projects::BATCH_SIZE) do |batch, index|
        range = batch.pluck(Arel.sql('MIN(id)'), Arel.sql('MAX(id)')).first
        count = index * batch.size * Gitlab::Seeder::Projects.projects_per_user_count

        Gitlab::Seeder.log_message("Creating projects namespaces: #{count}.")
        ActiveRecord::Base.connection.execute(Gitlab::Seeder::Projects.insert_project_namespaces_sql(type: 'Group', range: range))

        Gitlab::Seeder.log_message("Creating projects: #{count}.")
        ActiveRecord::Base.connection.execute(Gitlab::Seeder::Projects.insert_projects_sql(type: 'Group', range: range))
      end
    end
  end
end

Gitlab::Seeder.quiet do
  projects = Gitlab::Seeder::GroupProjects.new
  projects.seed!
end
