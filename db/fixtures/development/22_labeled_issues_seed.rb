# Creates a project with labeled issues for a user.
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
      puts '.'

      create_projects(group)
      puts '.'

      create_labels(group)
      puts '.'

      create_issues(group)
      puts '.'
    end

    print '.'
  end

  private

  def create_group
    group_name = "group_of_#{@user.name}#{SecureRandom.hex(4)}"

    group = Group.new(
      name: group_name,
      path: group_name,
      description: FFaker::Lorem.sentence
    )

    group.save

    group.add_owner(@user)

    group
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
        Labels::CreateService.new(title: label_title).execute(project: project)
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

      50.times do
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
