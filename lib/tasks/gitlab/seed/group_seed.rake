# frozen_string_literal: true

# Seed test groups with:
#   1. 2 Subgroups per level
#   1. 2 Users & group members per group
#   1. 2 Epics, 2 Milestones & 2 Projects per group
#   1. Project issues
#
# It also assigns each project's issue with one of group's or ascendants
# groups milestone & epic.
#
# @param subgroups_depth - number of subgroup levels
# @param username - user creating subgroups (i.e. GitLab admin)
# @param organization_path - organization where the groups will be created
#
# @example
#   bundle exec rake "gitlab:seed:group_seed[5, root, default]"
#
namespace :gitlab do
  namespace :seed do
    desc 'Seed groups with sub-groups/projects/epics/milestones for Group Import testing'
    task :group_seed, [:subgroups_depth, :username, :organization_path] => :gitlab_environment do |_t, args|
      require 'sidekiq/testing'
      require_relative '../../../gitlab/faker/internet'

      GroupSeeder.new(
        subgroups_depth: args.subgroups_depth,
        username: args.username,
        organization_path: args.organization_path
      ).seed
    end
  end
end

class GroupSeeder
  PROJECT_URL = 'https://gitlab.com/gitlab-org/gitlab-test.git'

  attr_reader :all_group_ids

  def initialize(subgroups_depth:, username:, organization_path:)
    @subgroups_depth = subgroups_depth.to_i
    @user = User.find_by_username(username)
    @group_names = Set.new
    @resource_count = 2
    @all_groups = {}
    @all_group_ids = []
    @organization = Organizations::Organization.find_by_path(organization_path)
  end

  def seed
    raise 'User must belong to the organization' unless @organization.user?(@user)

    create_groups

    puts 'Done!'
  end

  def create_groups
    create_root_group
    create_sub_groups
    create_users_and_members
    create_epics if Gitlab.ee?
    create_labels
    create_milestones

    Sidekiq::Testing.inline! do
      create_projects
    end
  end

  def create_users_and_members
    all_group_ids.each do |group_id|
      @resource_count.times do |_|
        user = create_user
        create_member(user.id, group_id)
      end
    end
  end

  def create_root_group
    root_group = ::Groups::CreateService.new(@user, group_params).execute[:group]

    track_group_id(1, root_group.id)
  end

  def create_sub_groups
    (2..@subgroups_depth).each do |level|
      parent_level = level - 1
      current_level = level
      parent_groups = @all_groups[parent_level]

      parent_groups.each do |parent_id|
        @resource_count.times do |_|
          sub_group = ::Groups::CreateService.new(@user, group_params(parent_id: parent_id)).execute[:group]

          track_group_id(current_level, sub_group.id)
        end
      end
    end
  end

  def track_group_id(depth_level, group_id)
    @all_groups[depth_level] ||= []
    @all_groups[depth_level] << group_id
    @all_group_ids << group_id
  end

  def group_params(parent_id: nil)
    name = unique_name

    {
      name: name,
      path: name,
      parent_id: parent_id,
      organization_id: @organization.id
    }
  end

  def unique_name
    name = ffaker_name
    name = ffaker_name until @group_names.add?(name)
    name
  end

  def ffaker_name
    FFaker::Lorem.characters(5)
  end

  def create_user
    User.create!(
      username: Gitlab::Faker::Internet.unique_username,
      name: FFaker::Name.name,
      email: FFaker::Internet.unique.email,
      confirmed_at: DateTime.now,
      password: Devise.friendly_token
    ) do |user|
      user.assign_personal_namespace(@organization)
    end
  end

  def create_member(user_id, group_id)
    roles = Gitlab::Access.values

    GroupMember.create(user_id: user_id, access_level: roles.sample, source_id: group_id)
  end

  def create_epics
    all_group_ids.each do |group_id|
      @resource_count.times do |_|
        group = Group.find(group_id)

        author = group.group_members.non_invite.sample.user
        epic_params = {
          title: FFaker::Lorem.sentence(6),
          description: FFaker::Lorem.paragraphs(3).join("\n\n"),
          author: author,
          group: group
        }

        ::Epics::CreateService.new(group: group, current_user: author, params: epic_params).execute
      end
    end
  end

  def create_labels
    all_group_ids.each do |group_id|
      @resource_count.times do |_|
        group = Group.find(group_id)
        label_title = FFaker::Product.brand

        Labels::CreateService.new(title: label_title, color: ::Gitlab::Color.color_for(label_title).to_s).execute(group: group)
      end
    end
  end

  def create_milestones
    all_group_ids.each do |group_id|
      @resource_count.times do |i|
        group = Group.find(group_id)

        milestone_params = {
          title: "v#{i}.0",
          description: FFaker::Lorem.sentence,
          state: [:active, :closed].sample
        }

        Milestones::CreateService.new(group, group.members.sample, milestone_params).execute
      end
    end
  end

  def create_projects
    all_group_ids.each do |group_id|
      group = Group.find(group_id)

      @resource_count.times do |i|
        _, project_path = PROJECT_URL.split('/')[-2..]

        project_path.gsub!('.git', '')

        params = {
          import_url: PROJECT_URL,
          namespace_id: group.id,
          name: project_path.titleize + FFaker::Lorem.characters(10),
          description: FFaker::Lorem.sentence,
          visibility_level: 0,
          skip_disk_validation: true
        }

        project = nil

        Sidekiq::Worker.skipping_transaction_check do
          project = ::Projects::CreateService.new(@user, params).execute
          project.send(:_run_after_commit_queue)
          project.import_state.send(:_run_after_commit_queue)
          project.repository.expire_all_method_caches
        end

        create_project_issues(project)
        assign_issues_to_epics_and_milestones(project)
      end
    end
  end

  def create_project_issues(project)
    seeder = Quality::Seeders::Issues.new(project: project)
    seeder.seed(backfill_weeks: 2, average_issues_per_week: 2)
  end

  def assign_issues_to_epics_and_milestones(project)
    group_ids = project.group.self_and_ancestors.map(&:id)

    project.issues.each do |issue|
      issue_params = {
        milestone: Milestone.where(group: group_ids).sample
      }

      issue_params[:epic] = Epic.where(group: group_ids).sample if Gitlab.ee?

      issue.update(issue_params)
    end
  end
end
