# == Schema Information
#
# Table name: projects
#
#  id                     :integer          not null, primary key
#  name                   :string(255)
#  path                   :string(255)
#  description            :text
#  created_at             :datetime
#  updated_at             :datetime
#  creator_id             :integer
#  issues_enabled         :boolean          default(TRUE), not null
#  wall_enabled           :boolean          default(TRUE), not null
#  merge_requests_enabled :boolean          default(TRUE), not null
#  wiki_enabled           :boolean          default(TRUE), not null
#  namespace_id           :integer
#  issues_tracker         :string(255)      default("gitlab"), not null
#  issues_tracker_id      :string(255)
#  snippets_enabled       :boolean          default(TRUE), not null
#  last_activity_at       :datetime
#  import_url             :string(255)
#  visibility_level       :integer          default(0), not null
#  archived               :boolean          default(FALSE), not null
#  avatar                 :string(255)
#  import_status          :string(255)
#  repository_size        :float            default(0.0)
#  star_count             :integer          default(0), not null
#  import_type            :string(255)
#  import_source          :string(255)
#  commit_count           :integer          default(0)
#  import_error           :text
#  ci_id                  :integer
#  builds_enabled         :boolean          default(TRUE), not null
#  shared_runners_enabled :boolean          default(TRUE), not null
#  runners_token          :string
#  build_coverage_regex   :string
#  build_allow_git_fetch  :boolean          default(TRUE), not null
#  build_timeout          :integer          default(3600), not null
#

FactoryGirl.define do
  # Project without repository
  #
  # Project does not have bare repository.
  # Use this factory if you dont need repository in tests
  factory :empty_project, class: 'Project' do
    sequence(:name) { |n| "project#{n}" }
    path { name.downcase.gsub(/\s/, '_') }
    namespace
    creator
    snippets_enabled true

    trait :public do
      visibility_level Gitlab::VisibilityLevel::PUBLIC
    end

    trait :internal do
      visibility_level Gitlab::VisibilityLevel::INTERNAL
    end

    trait :private do
      visibility_level Gitlab::VisibilityLevel::PRIVATE
    end
  end

  # Project with empty repository
  #
  # This is a case when you just created a project
  # but not pushed any code there yet
  factory :project_empty_repo, parent: :empty_project do
    after :create do |project|
      project.create_repository
    end
  end

  # Project with test repository
  #
  # Test repository source can be found at
  # https://gitlab.com/gitlab-org/gitlab-test
  factory :project, parent: :empty_project do
    path { 'gitlabhq' }

    after :create do |project|
      TestEnv.copy_repo(project)
    end
  end

  factory :forked_project_with_submodules, parent: :empty_project do
    path { 'forked-gitlabhq' }

    after :create do |project|
      TestEnv.copy_forked_repo_with_submodules(project)
    end
  end

  factory :redmine_project, parent: :project do
    after :create do |project|
      project.create_redmine_service(
        active: true,
        properties: {
          'project_url' => 'http://redmine/projects/project_name_in_redmine',
          'issues_url' => "http://redmine/#{project.id}/project_name_in_redmine/:id",
          'new_issue_url' => 'http://redmine/projects/project_name_in_redmine/issues/new'
        }
      )

      project.issues_tracker = 'redmine'
      project.issues_tracker_id = 'project_name_in_redmine'
    end
  end

  factory :jira_project, parent: :project do
    after :create do |project|
      project.create_jira_service(
        active: true,
        properties: {
          'title'         => 'JIRA tracker',
          'project_url'   => 'http://jira.example/issues/?jql=project=A',
          'issues_url'    => 'http://jira.example/browse/:id',
          'new_issue_url' => 'http://jira.example/secure/CreateIssue.jspa'
        }
      )

      project.issues_tracker = 'jira'
      project.issues_tracker_id = 'project_name_in_jira'
    end
  end
end
