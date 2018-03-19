# Creates a project with labeled issues for an user.
# Run this single seed file using: rake db:seed_fu FILTER=labeled USER_ID=74.
# If an USER_ID is not provided it will use the last created user.
require './spec/support/sidekiq'

class Gitlab::Seeder::LabeledIssues
  include ::Gitlab::Utils

  def initialize(user)
    @user = user
  end

  def seed!
    Sidekiq::Testing.inline! do
      group = create_group

      create_projects(group)
      create_labels(group)
      create_issues(group)
    end

    print '.'
  end

  private

  def create_group
    group_name = "group_of_#{@user.username}_#{SecureRandom.hex(4)}"

    group_params = {
      name: group_name,
      path: group_name,
      description: FFaker::Lorem.sentence
    }

    Groups::CreateService.new(@user, group_params).execute
  end

  def create_projects(group)
    5.times do
      project_name = "project_#{SecureRandom.hex(6)}"

      params = {
        namespace_id: group.id,
        name: project_name,
        description: FFaker::Lorem.sentence,
        visibility_level: Gitlab::VisibilityLevel.values.sample
      }

      Projects::CreateService.new(@user, params).execute
    end
  end

  def create_labels(group)
    group.projects.each do |project|
      5.times do
        label_title = FFaker::Vehicle.model
        Labels::CreateService.new(title: label_title, color: "#69D100").execute(project: project)
      end
    end

    10.times do
      label_title = FFaker::Product.brand
      Labels::CreateService.new(title: label_title).execute(group: group)
    end
  end

  def create_issues(group)
    # Get only group labels
    group_labels =
      LabelsFinder.new(@user, group_id: group.id).execute.where.not(group_id: nil)

    group.projects.each do |project|
      label_ids = project.labels.pluck(:id).sample(5)
      label_ids.push(*group.labels.sample(4))

      20.times do
        issue_params = {
          title: FFaker::Lorem.sentence(6),
          description: FFaker::Lorem.sentence,
          state: 'opened',
          label_ids: label_ids

        }

        Issues::CreateService.new(project, @user, issue_params).execute if project.project_feature.present?
      end
    end
  end
end

Gitlab::Seeder.quiet do
  user_id = ENV['USER_ID']

  user =
    if user_id.present?
      User.find(user_id)
    else
      User.last
    end

  Gitlab::Seeder::LabeledIssues.new(user).seed!
end
