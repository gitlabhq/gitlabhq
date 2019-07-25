# frozen_string_literal: true

require_relative '../support/helpers/test_env'

FactoryBot.define do
  PAGES_ACCESS_LEVEL_SCHEMA_VERSION ||= 20180423204600

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

    transient do
      # Nest Project Feature attributes
      wiki_access_level ProjectFeature::ENABLED
      builds_access_level ProjectFeature::ENABLED
      snippets_access_level ProjectFeature::ENABLED
      issues_access_level ProjectFeature::ENABLED
      merge_requests_access_level ProjectFeature::ENABLED
      repository_access_level ProjectFeature::ENABLED
      pages_access_level do
        visibility_level == Gitlab::VisibilityLevel::PUBLIC ? ProjectFeature::ENABLED : ProjectFeature::PRIVATE
      end

      # we can't assign the delegated `#ci_cd_settings` attributes directly, as the
      # `#ci_cd_settings` relation needs to be created first
      group_runners_enabled nil
      import_status nil
      import_jid nil
    end

    after(:create) do |project, evaluator|
      # Builds and MRs can't have higher visibility level than repository access level.
      builds_access_level = [evaluator.builds_access_level, evaluator.repository_access_level].min
      merge_requests_access_level = [evaluator.merge_requests_access_level, evaluator.repository_access_level].min

      hash = {
        wiki_access_level: evaluator.wiki_access_level,
        builds_access_level: builds_access_level,
        snippets_access_level: evaluator.snippets_access_level,
        issues_access_level: evaluator.issues_access_level,
        merge_requests_access_level: merge_requests_access_level,
        repository_access_level: evaluator.repository_access_level
      }

      if ActiveRecord::Migrator.current_version >= PAGES_ACCESS_LEVEL_SCHEMA_VERSION
        hash.store("pages_access_level", evaluator.pages_access_level)
      end

      project.project_feature.update(hash)

      # Normally the class Projects::CreateService is used for creating
      # projects, and this class takes care of making sure the owner and current
      # user have access to the project. Our specs don't use said service class,
      # thus we must manually refresh things here.
      unless project.group || project.pending_delete
        project.add_maintainer(project.owner)
      end

      project.group&.refresh_members_authorized_projects

      # assign the delegated `#ci_cd_settings` attributes after create
      project.reload.group_runners_enabled = evaluator.group_runners_enabled unless evaluator.group_runners_enabled.nil?

      if evaluator.import_status
        import_state = project.import_state || project.build_import_state
        import_state.status = evaluator.import_status
        import_state.jid = evaluator.import_jid
        import_state.save
      end
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

    trait :import_scheduled do
      import_status :scheduled
    end

    trait :import_started do
      import_status :started
    end

    trait :import_finished do
      import_status :finished
    end

    trait :import_failed do
      import_status :failed
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
      after(:create) do |project, _evaluator|
        ProjectExportWorker.new.perform(project.creator.id, project.id)
      end
    end

    trait :broken_storage do
      after(:create) do |project|
        project.update_column(:repository_storage, 'broken')
      end
    end

    # Build a custom repository by specifying a hash of `filename => content` in
    # the transient `files` attribute. Each file will be created in its own
    # commit, operating against the master branch. So, the following call:
    #
    #     create(:project, :custom_repo, files: { 'foo/a.txt' => 'foo', 'b.txt' => bar' })
    #
    # will create a repository containing two files, and two commits, in master
    trait :custom_repo do
      transient do
        files {}
      end

      after :create do |project, evaluator|
        raise "Failed to create repository!" unless project.create_repository

        evaluator.files.each do |filename, content|
          project.repository.create_file(
            project.creator,
            filename,
            content,
            message: "Automatically created file #{filename}",
            branch_name: 'master'
          )
        end
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

    trait :stubbed_repository do
      after(:build) do |project|
        allow(project).to receive(:empty_repo?).and_return(false)
        allow(project.repository).to receive(:empty?).and_return(false)
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
    trait(:merge_requests_public)   { merge_requests_access_level ProjectFeature::PUBLIC }
    trait(:repository_enabled)      { repository_access_level ProjectFeature::ENABLED }
    trait(:repository_disabled)     { repository_access_level ProjectFeature::DISABLED }
    trait(:repository_private)      { repository_access_level ProjectFeature::PRIVATE }
    trait(:pages_public)            { pages_access_level ProjectFeature::PUBLIC }
    trait(:pages_enabled)           { pages_access_level ProjectFeature::ENABLED }
    trait(:pages_disabled)          { pages_access_level ProjectFeature::DISABLED }
    trait(:pages_private)           { pages_access_level ProjectFeature::PRIVATE }

    trait :auto_devops do
      association :auto_devops, factory: :project_auto_devops
    end

    trait :auto_devops_disabled do
      association :auto_devops, factory: [:project_auto_devops, :disabled]
    end
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

    redmine_service
  end

  factory :youtrack_project, parent: :project do
    has_external_issue_tracker true

    youtrack_service
  end

  factory :jira_project, parent: :project do
    has_external_issue_tracker true

    jira_service
  end

  factory :kubernetes_project, parent: :project do
    kubernetes_service
  end

  factory :mock_deployment_project, parent: :project do
    mock_deployment_service
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
