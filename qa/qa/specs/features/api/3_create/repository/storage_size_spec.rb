# frozen_string_literal: true

module QA
  RSpec.describe 'Create' do
    describe 'Repository Usage Quota', :skip_live_env, product_group: :source_code, feature_flag: {
      name: 'gitaly_revlist_for_repo_size',
      scope: :global
    } do
      let(:project_name) { "repository-usage-#{SecureRandom.hex(8)}" }
      let!(:flag_enabled) { Runtime::Feature.enabled?(:gitaly_revlist_for_repo_size) }

      before do
        Runtime::Feature.enable(:gitaly_revlist_for_repo_size)
      end

      after do
        Runtime::Feature.set({ gitaly_revlist_for_repo_size: flag_enabled })
      end

      # Previously, GitLab could report a size many times larger than a cloned copy. For example, 37Gb reported for a
      # repo that is 2Gb when cloned.
      #
      # After changing Gitaly to use `git rev-list` to determine the size of a repo, the reported size is much more
      # accurate. Nonetheless, the size of a clone is still not necessarily the same as the original. We can't do a
      # precise comparison because of the non-deterministic nature of how git packs files. Depending on the history of
      # the repository the sizes can vary considerably. For example, at the time of writing this a clone of
      # www-gitlab-com was 5.27Gb, about 5% smaller than the size GitLab reported, 5.51Gb.
      #
      # There are unit tests to verify the accuracy of GitLab's determination of repo size, so for this test we
      # attempt to detect large differences that could indicate a regression to previous behavior.
      it 'matches cloned repo usage to reported usage', :blocking,
        testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/365196' do
        project = create(:project, name: project_name)

        shared_data = SecureRandom.random_bytes(500000)

        Resource::Repository::ProjectPush.fabricate! do |push|
          push.project = project
          push.file_name = 'data.dat'
          push.file_content = SecureRandom.random_bytes(500000) + shared_data
          push.commit_message = 'Add file'
        end

        local_size = Git::Repository.perform do |repository|
          repository.uri = project.repository_http_location.uri
          repository.use_default_credentials
          repository.default_branch = project.default_branch
          repository.clone
          repository.configure_identity('GitLab QA', 'root@gitlab.com')
          # These two commits add a total of 1mb, but half of that is the same as content that has already been added to
          # the repository, so garbage collection will deduplicate it.
          repository.commit_file("new-data", SecureRandom.random_bytes(500000), "Add file")
          repository.commit_file("redudant-data", shared_data, "Add file")
          repository.run_gc
          repository.push_changes
          repository.local_size
        end

        # The size of the remote repository after all content has been added.
        initial_size = project.statistics[:repository_size].to_i

        # This is an async process and as a user we have no way to know when it's complete unless the statistics are
        # updated
        Support::Retrier.retry_until(max_duration: 60, sleep_interval: 5) do
          # This should perform the same deduplication as in the local repo
          project.perform_housekeeping

          project.statistics[:repository_size].to_i != initial_size
        end

        twentyfive_percent = local_size.to_i * 0.25
        expect(project.statistics[:repository_size].to_i).to be_within(twentyfive_percent).of(local_size)
      end
    end
  end
end
