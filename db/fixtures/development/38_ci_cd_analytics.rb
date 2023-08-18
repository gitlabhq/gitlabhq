# frozen_string_literal: true

require './ee/db/seeds/shared/dora_metrics' if Gitlab.ee?

# Usage:
#
# Simple invocation always creates a new project within a group:
#
# FILTER=ci_cd_analytics SEED_CI_CD_ANALYTICS=1 bundle exec rake db:seed_fu

# rubocop:disable Rails/Output
class Gitlab::Seeder::CiAnalytics # rubocop:disable Style/ClassAndModuleChildren
  FLAG = 'SEED_CI_CD_ANALYTICS'

  def initialize
    @project = create_new_project
  end

  def seed!
    seed_data!
  end

  private

  attr_reader :project

  def seed_data!
    Sidekiq::Worker.skipping_transaction_check do
      create_dora_metrics! if Gitlab.ee?
      create_pipelines!
      create_releases!

      puts "Successfully seeded '#{project.full_path}' for CI/CD analytics!"
      puts "URL: #{Rails.application.routes.url_helpers.project_url(project)}"
    end
  end

  def create_new_project
    namespace = FactoryBot.create(
      :group,
      name: "CICD analytics Group #{suffix}",
      path: "cicd-#{suffix}"
    )
    project = FactoryBot.create(
      :project,
      :repository,
      name: "CICD analytics Project #{suffix}",
      path: "cicd-#{suffix}",
      creator: admin,
      namespace: namespace
    )

    namespace.add_owner(admin)
    project.create_repository
    project
  end

  def create_dora_metrics!
    Gitlab::Seeder::DoraMetrics.new(project: project).execute
  end

  def create_pipelines!
    branches = project.repository.branches.sample(15)
    pipeline_statuses = [:success, :failed]

    branches.each do |branch|
      FactoryBot.create(
        :ci_pipeline,
        pipeline_statuses.sample,
        project: project,
        ref: branch.name,
        sha: branch.target,
        created_at: random_past_date,
        duration: rand(10).hours
      )
    end
  end

  def create_releases!
    FactoryBot.create_list(:release, 3, project: project, author: admin)
  end

  def admin
    @admin ||= User.admins.first
  end

  def suffix
    @suffix ||= Time.now.to_i
  end

  def random_past_date
    rand(120).days.ago
  end
end

Gitlab::Seeder.quiet do
  if ENV[Gitlab::Seeder::CiAnalytics::FLAG]
    Gitlab::Seeder::CiAnalytics.new.seed!
  else
    puts "Skipped. Use the `#{Gitlab::Seeder::CiAnalytics::FLAG}` environment variable to enable."
  end
end
# rubocop:enable Rails/Output
