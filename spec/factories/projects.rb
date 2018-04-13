require_relative '../support/helpers/test_env'

FactoryBot.define do
  # Project without repository
  #
  # Project does not have bare repository.
  # Use this factory if you don't need repository in tests
  factory :project, class: 'Project' do
    sequence(:name) { |n| "project#{n}" }
    path { name.downcase.gsub(/\s/, '_') }
    # Behaves differently to nil due to cache_has_external_issue_tracker
    has_external_issue_tracker false

    # Associations
    namespace
    creator { group ? create(:user) : namespace&.owner }

    # Nest Project Feature attributes
    transient do
      wiki_access_level ProjectFeature::ENABLED
      builds_access_level ProjectFeature::ENABLED
      snippets_access_level ProjectFeature::ENABLED
      issues_access_level ProjectFeature::ENABLED
      merge_requests_access_level ProjectFeature::ENABLED
      repository_access_level ProjectFeature::ENABLED
    end

    after(:create) do |project, evaluator|
      # Builds and MRs can't have higher visibility level than repository access level.
      builds_access_level = [evaluator.builds_access_level, evaluator.repository_access_level].min
      merge_requests_access_level = [evaluator.merge_requests_access_level, evaluator.repository_access_level].min

      project.project_feature.update_columns(
        wiki_access_level: evaluator.wiki_access_level,
        builds_access_level: builds_access_level,
        snippets_access_level: evaluator.snippets_access_level,
        issues_access_level: evaluator.issues_access_level,
        merge_requests_access_level: merge_requests_access_level,
        repository_access_level: evaluator.repository_access_level)

      # Normally the class Projects::CreateService is used for creating
      # projects, and this class takes care of making sure the owner and current
      # user have access to the project. Our specs don't use said service class,
      # thus we must manually refresh things here.
      unless project.group || project.pending_delete
        project.add_master(project.owner)
      end

      project.group&.refresh_members_authorized_projects
    end

    trait :public do
      visibility_level Gitlab::VisibilityLevel::PUBLIC
    end

    trait :internal do
      visibility_level Gitlab::VisibilityLevel::INTERNAL
    end

    trait :private do
      visibility_level Gitlab::VisibilityLevel::PRIVATE
    end

    trait :import_none do
      import_status :none
    end

    trait :import_scheduled do
      import_status :scheduled

      after(:create) do |project, _|
        project.mirror_data&.update_attributes(last_update_scheduled_at: Time.now)
      end
    end

    trait :import_started do
      import_status :started

      after(:create) do |project, _|
        project.mirror_data&.update_attributes(last_update_started_at: Time.now)
      end
    end

    trait :import_finished do
      timestamp = Time.now

      import_status :finished
      mirror_last_update_at timestamp
      mirror_last_successful_update_at timestamp
    end

    trait :import_failed do
      import_status :failed
      mirror_last_update_at { Time.now }
    end

    trait :import_hard_failed do
      import_status :failed
      mirror_last_update_at { Time.now - 1.minute }

      after(:create) do |project|
        project.mirror_data&.update_attributes(retry_count: Gitlab::Mirror::MAX_RETRY + 1)
      end
    end

    trait :mirror do
      mirror true
      import_url { generate(:url) }
      mirror_user_id { creator_id }
    end

    trait :archived do
      archived true
    end

    storage_version Project::LATEST_STORAGE_VERSION

    trait :legacy_storage do
      storage_version nil
    end

    trait :access_requestable do
      request_access_enabled true
    end

    trait :with_avatar do
      avatar { fixture_file_upload('spec/fixtures/dk.png') }
    end

    trait :with_export do
      after(:create) do |project, evaluator|
        ProjectExportWorker.new.perform(project.creator.id, project.id)
      end
    end

    trait :broken_storage do
      after(:create) do |project|
        project.update_column(:repository_storage, 'broken')
      end
    end

    # Test repository - https://gitlab.com/gitlab-org/gitlab-test
    trait :repository do
      test_repo

      transient do
        create_templates nil
      end

      after :create do |project, evaluator|
        if evaluator.create_templates
          templates_path = "#{evaluator.create_templates}_templates"

          project.repository.create_file(
            project.creator,
            ".gitlab/#{templates_path}/bug.md",
            'something valid',
            message: 'test 3',
            branch_name: 'master')
          project.repository.create_file(
            project.creator,
            ".gitlab/#{templates_path}/template_test.md",
            'template_test',
            message: 'test 1',
            branch_name: 'master')
          project.repository.create_file(
            project.creator,
            ".gitlab/#{templates_path}/feature_proposal.md",
            'feature_proposal',
            message: 'test 2',
            branch_name: 'master')
        end
      end
    end

    trait :empty_repo do
      after(:create) do |project|
        raise "Failed to create repository!" unless project.create_repository

        # We delete hooks so that gitlab-shell will not try to authenticate with
        # an API that isn't running
        project.gitlab_shell.rm_directory(project.repository_storage,
                                          File.join("#{project.disk_path}.git", 'hooks'))
      end
    end

    trait :remote_mirror do
      transient do
        remote_name "remote_mirror_#{SecureRandom.hex}"
        url "http://foo.com"
        enabled true
      end

      after(:create) do |project, evaluator|
        project.remote_mirrors.create!(url: evaluator.url, enabled: evaluator.enabled)
      end
    end

    trait :wiki_repo do
      after(:create) do |project|
        raise 'Failed to create wiki repository!' unless project.create_wiki
      end
    end

    trait :read_only do
      repository_read_only true
    end

    trait :broken_repo do
      after(:create) do |project|
        raise "Failed to create repository!" unless project.create_repository

        project.gitlab_shell.rm_directory(project.repository_storage,
                                          File.join("#{project.disk_path}.git", 'refs'))
      end
    end

    trait :test_repo do
      after :create do |project|
        TestEnv.copy_repo(project,
          bare_repo: TestEnv.factory_repo_path_bare,
          refs: TestEnv::BRANCH_SHA)
      end
    end

    trait :random_last_repository_updated_at do
      last_repository_updated_at { rand(1.year).seconds.ago }
    end

    trait(:wiki_enabled)            { wiki_access_level ProjectFeature::ENABLED }
    trait(:wiki_disabled)           { wiki_access_level ProjectFeature::DISABLED }
    trait(:wiki_private)            { wiki_access_level ProjectFeature::PRIVATE }
    trait(:builds_enabled)          { builds_access_level ProjectFeature::ENABLED }
    trait(:builds_disabled)         { builds_access_level ProjectFeature::DISABLED }
    trait(:builds_private)          { builds_access_level ProjectFeature::PRIVATE }
    trait(:snippets_enabled)        { snippets_access_level ProjectFeature::ENABLED }
    trait(:snippets_disabled)       { snippets_access_level ProjectFeature::DISABLED }
    trait(:snippets_private)        { snippets_access_level ProjectFeature::PRIVATE }
    trait(:issues_disabled)         { issues_access_level ProjectFeature::DISABLED }
    trait(:issues_enabled)          { issues_access_level ProjectFeature::ENABLED }
    trait(:issues_private)          { issues_access_level ProjectFeature::PRIVATE }
    trait(:merge_requests_enabled)  { merge_requests_access_level ProjectFeature::ENABLED }
    trait(:merge_requests_disabled) { merge_requests_access_level ProjectFeature::DISABLED }
    trait(:merge_requests_private)  { merge_requests_access_level ProjectFeature::PRIVATE }
    trait(:repository_enabled)      { repository_access_level ProjectFeature::ENABLED }
    trait(:repository_disabled)     { repository_access_level ProjectFeature::DISABLED }
    trait(:repository_private)      { repository_access_level ProjectFeature::PRIVATE }
  end

  # Project with empty repository
  #
  # This is a case when you just created a project
  # but not pushed any code there yet
  factory :project_empty_repo, parent: :project do
    empty_repo
  end

  # Project with broken repository
  #
  # Project with an invalid repository state
  factory :project_broken_repo, parent: :project do
    broken_repo
  end

  factory :forked_project_with_submodules, parent: :project do
    path { 'forked-gitlabhq' }

    after :create do |project|
      TestEnv.copy_repo(project,
        bare_repo: TestEnv.forked_repo_path_bare,
        refs: TestEnv::FORKED_BRANCH_SHA)
    end
  end

  factory :redmine_project, parent: :project do
    has_external_issue_tracker true

    after :create do |project|
      project.create_redmine_service(
        active: true,
        properties: {
          'project_url' => 'http://redmine/projects/project_name_in_redmine',
          'issues_url' => 'http://redmine/projects/project_name_in_redmine/issues/:id',
          'new_issue_url' => 'http://redmine/projects/project_name_in_redmine/issues/new'
        }
      )
    end
  end

  factory :jira_project, parent: :project do
    has_external_issue_tracker true
    jira_service
  end

  factory :kubernetes_project, parent: :project do
    kubernetes_service
  end

  factory :prometheus_project, parent: :project do
    after :create do |project|
      project.create_prometheus_service(
        active: true,
        properties: {
          api_url: 'https://prometheus.example.com/',
          manual_configuration: true
        }
      )
    end
  end
end
