# frozen_string_literal: true

module QA
  RSpec.describe 'Verify', feature_category: :pipeline_composition do
    describe 'Prevent duplicate merge request pipelines' do
      let(:project) { create(:project, name: 'prevent-duplicate-mr-pipelines', initialize_with_readme: true) }
      let(:source_branch) { "feature-#{SecureRandom.hex(8)}" }

      shared_examples 'creates both branch and merge request pipelines' do |testcase|
        it 'creates both branch and merge request pipelines on push to existing MR', testcase: testcase do
          create_mr_and_wait(project, source_branch, expected_new: 2)
          count_before = project.pipelines.size

          push_to_branch(project, source_branch)
          wait_for_new_pipelines(project, count_before, expected_new: 2)

          new_sources = new_pipeline_sources(project, count_before)
          expect(new_sources).to include('push')
          expect(new_sources).to include('merge_request_event')
        end
      end

      shared_examples 'creates only a merge request pipeline' do |testcase|
        it 'creates only a merge request pipeline on push to existing MR', testcase: testcase do
          create_mr_and_wait(project, source_branch, expected_new: 1)
          count_before = project.pipelines.size

          push_to_branch(project, source_branch)
          wait_for_new_pipelines(project, count_before, expected_new: 1)

          wait_for_pipeline_count_stability(project)

          new_sources = new_pipeline_sources(project, count_before)
          expect(new_sources).to contain_exactly('merge_request_event')
        end
      end

      shared_examples 'creates only a branch pipeline' do |testcase|
        it 'creates only a branch pipeline on push to existing MR', testcase: testcase do
          create_mr_and_wait(project, source_branch, expected_new: 1)
          count_before = project.pipelines.size

          push_to_branch(project, source_branch)
          wait_for_new_pipelines(project, count_before, expected_new: 1)

          wait_for_pipeline_count_stability(project)

          new_sources = new_pipeline_sources(project, count_before)
          expect(new_sources).to contain_exactly('push')
        end
      end

      context 'without workflow:rules' do
        before do
          commit_ci_config(project, <<~YAML)
            test_job:
              script: echo "hello"
          YAML
        end

        context 'when setting is disabled' do
          it_behaves_like 'creates only a branch pipeline',
            'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/604967'
        end

        context 'when setting is enabled' do
          before do
            project.change_skip_branch_pipelines_for_mrs(true)
          end

          it_behaves_like 'creates only a merge request pipeline',
            'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/604968'

          context 'with pipelines must succeed' do
            before do
              project.change_only_allow_merge_if_pipeline_succeeds(true)
            end

            it 'sets the merge request pipeline as head pipeline',
              testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/605642' do
              mr = create_mr_and_wait(project, source_branch, expected_new: 2)
              mr.wait_for_preparation

              expect_merge_request_pipeline_gating(mr)
            end
          end
        end
      end

      context 'with workflow:rules accepting both pipelines' do
        before do
          commit_ci_config(project, <<~YAML)
            workflow:
              rules:
                - if: $CI_MERGE_REQUEST_IID
                - if: $CI_COMMIT_BRANCH

            test_job:
              script: echo "hello"
          YAML
        end

        context 'when setting is disabled' do
          it_behaves_like 'creates both branch and merge request pipelines',
            'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/604965'
        end

        context 'when setting is enabled' do
          before do
            project.change_skip_branch_pipelines_for_mrs(true)
          end

          it_behaves_like 'creates only a merge request pipeline',
            'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/604966'
        end
      end

      context 'with workflow:rules accepting only MR pipelines' do
        before do
          commit_ci_config(project, <<~YAML)
            workflow:
              rules:
                - if: $CI_MERGE_REQUEST_IID

            test_job:
              script: echo "hello"
          YAML
        end

        context 'when setting is disabled' do
          it_behaves_like 'creates only a merge request pipeline',
            'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/605643'
        end

        context 'when setting is enabled' do
          before do
            project.change_skip_branch_pipelines_for_mrs(true)
          end

          it_behaves_like 'creates only a merge request pipeline',
            'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/605644'

          context 'with pipelines must succeed' do
            before do
              project.change_only_allow_merge_if_pipeline_succeeds(true)
            end

            it 'sets the merge request pipeline as head pipeline',
              testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/605647' do
              mr = create_mr_and_wait(project, source_branch, expected_new: 1)
              mr.wait_for_preparation

              expect_merge_request_pipeline_gating(mr)
            end
          end
        end
      end

      context 'with workflow:rules accepting only branch pipelines' do
        before do
          commit_ci_config(project, <<~YAML)
            workflow:
              rules:
                - if: $CI_COMMIT_BRANCH

            test_job:
              script: echo "hello"
          YAML
        end

        context 'when setting is disabled' do
          it_behaves_like 'creates only a branch pipeline',
            'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/605645'
        end

        context 'when setting is enabled' do
          before do
            project.change_skip_branch_pipelines_for_mrs(true)
          end

          it 'creates no pipeline on push to existing MR',
            testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/605646' do
            create_mr_and_wait(project, source_branch, expected_new: 1)
            count_before = project.pipelines.size

            push_to_branch(project, source_branch)

            wait_for_pipeline_count_stability(project)

            expect(project.pipelines.size).to eq(count_before)
          end

          context 'with pipelines must succeed' do
            before do
              project.change_only_allow_merge_if_pipeline_succeeds(true)
            end

            it 'is not mergeable when only a branch pipeline exists',
              testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/605648' do
              mr = create_mr_and_wait(project, source_branch, expected_new: 1)
              mr.wait_for_preparation

              expect { mr.reload!.detailed_merge_status }
                .to eventually_eq('ci_must_pass').within(max_duration: 60, sleep_interval: 2)
            end
          end
        end
      end

      context 'with invalid YAML' do
        before do
          commit_ci_config(project, "invalid: yaml: [content\n")
        end

        context 'when setting is disabled' do
          it_behaves_like 'creates both branch and merge request pipelines',
            'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/604969'
        end

        context 'when setting is enabled' do
          before do
            project.change_skip_branch_pipelines_for_mrs(true)
          end

          it_behaves_like 'creates only a merge request pipeline',
            'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/604970'
        end
      end

      private

      # When a merge request pipeline is the head pipeline and "pipelines must succeed" is on,
      # the MR is either still running that pipeline or already mergeable once it finishes.
      # Both are valid depending on runner timing, so accept either state to avoid racing on
      # the transient 'ci_still_running' status.
      def expect_merge_request_pipeline_gating(mr)
        valid_statuses = %w[ci_still_running mergeable]

        return if Support::Waiter.wait_until(max_duration: 60, sleep_interval: 2, raise_on_failure: false) do
          valid_statuses.include?(mr.reload!.detailed_merge_status)
        end

        raise Support::Repeater::WaitExceededError,
          "Expected merge request detailed_merge_status to be one of #{valid_statuses}, " \
            "but was '#{mr.detailed_merge_status}'"
      end

      def commit_ci_config(project, content)
        create(:commit, project: project, commit_message: 'Add .gitlab-ci.yml', actions: [
          { action: 'create', file_path: '.gitlab-ci.yml', content: content }
        ])
      end

      def create_mr_and_wait(project, branch, expected_new:)
        count_before = project.pipelines.size

        mr = create(:merge_request,
          project: project,
          source_branch: branch,
          target_new_branch: false,
          file_name: "initial-#{SecureRandom.hex(8)}.txt",
          file_content: 'initial content')

        wait_for_new_pipelines(project, count_before, expected_new: expected_new)
        wait_for_pipeline_count_stability(project)
        mr
      end

      def push_to_branch(project, branch)
        create(:commit,
          project: project,
          branch: branch,
          commit_message: 'Push to existing MR',
          actions: [
            { action: 'create', file_path: "update-#{SecureRandom.hex(8)}.txt", content: 'updated content' }
          ])
      end

      def wait_for_new_pipelines(project, count_before, expected_new:)
        Support::Waiter.wait_until(max_duration: 60, sleep_interval: 3,
          message: "Wait for #{expected_new} new pipeline(s)") do
          project.pipelines.size >= count_before + expected_new
        end
      end

      def wait_for_pipeline_count_stability(project)
        Support::Waiter.wait_until(max_duration: 10, sleep_interval: 2,
          message: 'Confirm no additional pipeline is created') do
          size_before = project.pipelines.size
          sleep 2
          project.pipelines.size == size_before
        end
      end

      def new_pipeline_sources(project, count_before)
        new_pipelines_after(project, count_before).map { |p| p[:source] }
      end

      def new_pipelines_after(project, count_before)
        all_pipelines = project.pipelines.sort_by { |p| p[:id] }
        all_pipelines.last(all_pipelines.size - count_before)
      end
    end
  end
end
