# frozen_string_literal: true

require './db/fixtures/development/03_project'

class Gitlab::Seeder::UserProjects
  def seed!
    create_user_projects!
  end

  private

  def create_user_projects!
    user_namespaces = Namespace.where("path LIKE ?", "#{Gitlab::Seeder::MASS_INSERT_PREFIX}%").where(type: 'User')

    Gitlab::Seeder.with_mass_insert(user_namespaces.count * Gitlab::Seeder::Projects.projects_per_user_count, "User projects and corresponding project namespaces") do
      user_namespaces.each_batch(of: Gitlab::Seeder::Projects::BATCH_SIZE) do |batch, index|
        range = batch.pluck(Arel.sql('MIN(id)'), Arel.sql('MAX(id)')).first
        count = index * batch.size * Gitlab::Seeder::Projects.projects_per_user_count

        Gitlab::Seeder.log_message("Creating project namespaces: #{count}.")
        ActiveRecord::Base.connection.execute(Gitlab::Seeder::Projects.insert_project_namespaces_sql(type: 'User', range: range))

        Gitlab::Seeder.log_message("Creating projects: #{count}.")
        ActiveRecord::Base.connection.execute(Gitlab::Seeder::Projects.insert_projects_sql(type: 'User', range: range))
      end
    end
  end
end

Gitlab::Seeder.quiet do
  projects = Gitlab::Seeder::UserProjects.new
  projects.seed!
end
