# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Commits', feature_category: :source_code_management do
  let_it_be(:project, freeze: false) { create(:project, :repository) }
  let_it_be(:user) { create(:user) }

  let(:ref_selector) { '.ref-selector' }
  let(:ref_with_hash) { 'ref-#-hash' }

  def switch_ref_to(ref_name)
    find(ref_selector).click
    wait_for_requests

    page.within ref_selector do
      fill_in 'Search by Git revision', with: ref_name
      wait_for_requests
      find('li', text: ref_name, match: :prefer_exact).click
    end
  end

  describe 'CI' do
    before do
      sign_in(user)
      stub_ci_pipeline_to_return_yaml_file
    end

    let(:creator) { create(:user, developer_of: project) }
    let!(:pipeline) do
      create(
        :ci_pipeline,
        project: project,
        user: creator,
        ref: project.default_branch,
        sha: project.commit.sha,
        status: :success,
        created_at: 5.months.ago
      )
    end

    context 'commit status is Generic Commit Status' do
      let(:stage) { create(:ci_stage, pipeline: pipeline, name: 'external') }
      let!(:status) { create(:generic_commit_status, pipeline: pipeline, ref: pipeline.ref, ci_stage: stage) }

      before do
        project.add_reporter(user)
      end

      describe 'Commit builds', :js do
        before do
          visit builds_project_pipeline_path(project, pipeline)

          wait_for_requests
        end

        it 'contains commit short id' do
          within_testid('pipeline-header') do
            expect(page).to have_content pipeline.sha[0..7]
          end
        end

        it 'contains generic commit status build' do
          within_testid('jobs-tab-table') do
            expect(page).to have_content "##{status.id}" # build id
            expect(page).to have_content 'generic'       # build name
          end
        end
      end
    end

    context 'commit status is Ci Build' do
      let!(:build) { create(:ci_build, pipeline: pipeline) }
      let(:artifacts_file) { fixture_file_upload('spec/fixtures/banana_sample.gif', 'image/gif') }

      context 'when logged as developer' do
        before do
          project.add_developer(user)
        end

        describe 'Project commits', :js do
          let_it_be(:commit_short_id) { project.commit.short_id }

          let!(:pipeline_from_other_branch) do
            create(
              :ci_pipeline,
              project: project,
              ref: 'fix',
              sha: project.commit.sha,
              status: :failed
            )
          end

          context 'while viewing a branch' do
            before do
              visit project_commits_path(project, :master)
            end

            it 'shows correct build status from default branch', :aggregate_failures do
              page.within("#commit-#{commit_short_id}") do
                expect(page).to have_css("[data-testid='ci-icon']")
                expect(page).to have_css('[data-testid="status_success_borderless-icon"]')
              end
            end
          end

          # Regression test for https://gitlab.com/gitlab-org/gitlab/-/issues/579690:
          # a dangling-source pipeline (e.g. a security policy scan) newer than the
          # commit's real CI pipeline must not determine the badge status.
          context 'when a newer dangling pipeline exists' do
            # Newer than the default-branch pipeline above, so it is the latest CI-source pipeline.
            let!(:failed_ci_pipeline) do
              create(
                :ci_pipeline,
                project: project,
                ref: project.default_branch,
                sha: project.commit.sha,
                status: :failed,
                source: :push
              )
            end

            # Newest pipeline overall and green; a naive "latest of any source" would surface this.
            let!(:dangling_pipeline) do
              create(
                :ci_pipeline,
                project: project,
                ref: project.default_branch,
                sha: project.commit.sha,
                status: :success,
                source: :security_orchestration_policy
              )
            end

            before do
              visit project_commits_path(project, :master)
            end

            it 'shows the CI pipeline status and ignores the dangling pipeline', :aggregate_failures do
              page.within("#commit-#{commit_short_id}") do
                expect(page).to have_css("[data-testid='ci-icon']")
                expect(page).to have_css('[data-testid="status_failed_borderless-icon"]')
              end
            end
          end

          context 'while viewing a commit' do
            let_it_be(:sha) { project.commit.sha }
            let_it_be(:short_sha) { sha[..7] }

            before_all do
              project.repository.add_branch(user, sha, 'master', skip_ci: true)
              project.repository.add_branch(user, short_sha, 'master', skip_ci: true)
            end

            context 'when ref is a commit short sha' do
              context 'without ref_type' do
                before do
                  visit project_commits_path(project, short_sha)
                end

                # Git prioritizes matching short SHAs to branches over commits
                it 'does not show any build status' do
                  page.within("#commit-#{commit_short_id}") do
                    expect(page).not_to have_css("[data-testid='ci-icon']")
                  end
                end
              end

              context 'with ref_type' do
                before do
                  visit project_commits_path(project, short_sha, ref_type: 'heads')
                end

                it 'does not show any build status' do
                  page.within("#commit-#{commit_short_id}") do
                    expect(page).not_to have_css("[data-testid='ci-icon']")
                  end
                end
              end
            end

            context 'when ref is a commit sha' do
              context 'without ref_type' do
                before do
                  visit project_commits_path(project, sha)
                end

                it 'shows latest build status for the commit sha', :aggregate_failures do
                  page.within("#commit-#{commit_short_id}") do
                    expect(page).to have_css("[data-testid='ci-icon']")
                    expect(page).to have_css('[data-testid="status_failed_borderless-icon"]')
                  end
                end
              end

              context 'with ref_type' do
                before do
                  visit project_commits_path(project, sha, ref_type: 'heads')
                end

                it 'does not show any build status' do
                  page.within("#commit-#{commit_short_id}") do
                    expect(page).not_to have_css("[data-testid='ci-icon']")
                  end
                end
              end
            end
          end
        end

        describe 'Commit builds', :js do
          before do
            project.add_developer(user)
            visit pipeline_path(pipeline)
          end

          it 'shows pipeline data' do
            expect(page).to have_content pipeline.sha[0..7]
            expect(page).to have_content pipeline.user.name
          end
        end

        context 'Download artifacts', :js do
          before do
            create(:ci_job_artifact, :archive, file: artifacts_file, job: build)
          end

          it do
            visit builds_project_pipeline_path(project, pipeline)
            wait_for_requests
            expect(page).to have_link('Download artifacts', href: download_project_job_artifacts_path(project, build, file_type: :archive))
          end
        end

        describe 'Cancel jobs' do
          let!(:pipeline) do
            create(
              :ci_pipeline,
              project: project,
              user: creator,
              ref: project.default_branch,
              sha: project.commit.sha,
              status: :running,
              created_at: 5.months.ago
            )
          end

          before do
            visit pipeline_path(pipeline)
            wait_for_requests
            click_on 'Cancel pipeline'
            wait_for_requests
          end

          it 'cancels pipeline and jobs', :js, :sidekiq_might_not_need_inline do
            expect(page).to have_content 'Canceled'
          end
        end
      end

      context "when logged as reporter", :js do
        before do
          project.add_reporter(user)
          create(:ci_job_artifact, :archive, file: artifacts_file, job: build)
          visit builds_project_pipeline_path(project, pipeline)
          wait_for_requests
        end

        it 'renders header' do
          expect(page).to have_content pipeline.sha[0..7]
          expect(page).to have_content pipeline.user.name
          expect(page).not_to have_link('Cancel pipeline')
          expect(page).not_to have_link('Retry')
        end

        it do
          expect(page).to have_link('Download artifacts')
        end
      end

      context 'when accessing internal project with disallowed access', :js do
        before do
          project.add_reporter(user)
          project.update!(
            visibility_level: Gitlab::VisibilityLevel::INTERNAL,
            public_builds: false)
          create(:ci_job_artifact, :archive, file: artifacts_file, job: build)
          visit pipeline_path(pipeline)
        end

        it do
          expect(page).to have_content pipeline.sha[0..7]
          expect(page).to have_content pipeline.user.name

          expect(page).not_to have_link('Cancel pipeline')
          expect(page).not_to have_link('Retry')
        end
      end
    end
  end

  context 'viewing commits for a branch' do
    let(:branch_name) { 'master' }

    before do
      stub_feature_flags(project_commits_refactor: false)
      project.add_maintainer(user)
      sign_in(user)
      project.repository.create_branch(ref_with_hash, branch_name)
      visit project_commits_path(project, branch_name)
    end

    it 'includes a date on which the commits were authored' do
      commits = project.repository.commits(branch_name, limit: 40)
      commits.chunk { |c| c.committed_date.in_time_zone.to_date }.each do |day, _daily_commits|
        expect(page).to have_content(day.strftime("%b %d, %Y"))
      end
    end

    it 'includes the committed_date for each commit' do
      commits = project.repository.commits(branch_name, limit: 40)

      commits.each do |commit|
        expect(page).to have_content("authored #{commit.authored_date.strftime('%b %d, %Y')}")
      end
    end

    it 'switches ref to ref containing a hash', :js do
      switch_ref_to(ref_with_hash)

      expect(page).to have_selector ref_selector, text: ref_with_hash
    end

    it 'shows the ref switcher with the multi-file editor enabled', :js do
      set_cookie('new_repo', 'true')
      visit project_commits_path(project, branch_name)

      expect(find(ref_selector)).to have_content branch_name
    end
  end

  context 'viewing commits for a branch with refactored UI', :js do
    let(:branch_name) { 'master' }

    before do
      project.add_maintainer(user)
      sign_in(user)
      project.repository.create_branch(ref_with_hash, branch_name)
      visit project_commits_path(project, branch_name)
    end

    it 'shows commits grouped by day with dates', :aggregate_failures do
      commits = project.repository.commits(branch_name, limit: 20)
      # The UI renders day headers in the browser's (OS-local) timezone,
      # so mirror that with +localtime+ rather than +Time.zone+.
      expected_days = commits.map { |c| c.committed_date.localtime.strftime('%b %-d, %Y') }.uniq

      expect(page).to have_testid('daily-commits', count: expected_days.length)

      expected_days.each do |day|
        expect(page).to have_content(day)
      end

      within_testid('daily-commits', match: :first) do
        expect(page).to have_testid('daily-commits-date', text: expected_days.first)
        expect(page).to have_testid('commit-row', text: commits.first.title)
      end
    end

    it 'shows the author and a relative authored date for each commit', :aggregate_failures do
      commits = project.repository.commits(branch_name, limit: 20)

      expect(page).to have_testid('commit-row', count: commits.length)

      within_testid('commit-row', match: :first) do
        expect(page).to have_content("#{commits.first.author_name} authored")
        expect(page).to have_testid('commit-authored-date')
      end
    end

    it 'switches ref to ref containing a hash' do
      switch_ref_to(ref_with_hash)

      expect(page).to have_selector ref_selector, text: ref_with_hash
    end
  end

  context 'viewing commits for an author' do
    let(:author_commit) { project.repository.commits(nil, limit: 1).first }
    let(:commits) { project.repository.commits(nil, author: author, limit: 40) }

    before do
      stub_feature_flags(project_commits_refactor: false)
      project.add_maintainer(user)
      sign_in(user)
      visit project_commits_path(project, nil, author: author)
    end

    shared_examples 'show commits by author' do
      it "includes the author's commits" do
        commits.each do |commit|
          expect(page).to have_content("#{author_commit.author_name} authored #{commit.authored_date.strftime('%b %d, %Y')}")
        end
      end
    end

    context 'author is complete' do
      let(:author) { "#{author_commit.author_name} <#{author_commit.author_email}>" }

      it_behaves_like 'show commits by author'
    end

    context 'author is just a name' do
      let(:author) { author_commit.author_name.to_s }

      it_behaves_like 'show commits by author'
    end

    context 'author is just an email' do
      let(:author) { author_commit.author_email.to_s }

      it_behaves_like 'show commits by author'
    end
  end

  context 'viewing commits for an author with refactored UI', :js do
    let(:author_commit) { project.repository.commit }
    let(:other_author_commit) do
      # A commit on the first (unfiltered) page authored by someone else,
      # so it would be visible if author filtering did not work.
      project.repository.commits(nil, limit: 20).find do |commit|
        commit.author_email != author_commit.author_email
      end
    end

    before do
      project.add_maintainer(user)
      sign_in(user)
    end

    shared_examples 'show commits filtered by author' do
      it 'shows only commits by the selected author', :aggregate_failures do
        visit project_commits_path(project, nil, author: author)

        expect(page).to have_testid('commit-row')
        expect(page).to have_content("#{author_commit.author_name} authored")

        expect(page).not_to have_content("#{other_author_commit.author_name} authored")
        expect(page).not_to have_content(other_author_commit.title)
      end
    end

    context 'when author is specified as both a name and an email' do
      let(:author) { "#{author_commit.author_name} <#{author_commit.author_email}>" }

      it_behaves_like 'show commits filtered by author'
    end

    context 'when author is just a name' do
      let(:author) { author_commit.author_name.to_s }

      it_behaves_like 'show commits filtered by author'
    end

    context 'when author is just an email' do
      let(:author) { author_commit.author_email.to_s }

      it_behaves_like 'show commits filtered by author'
    end
  end
end
