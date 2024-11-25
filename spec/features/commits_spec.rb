# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Commits', feature_category: :source_code_management do
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:user) { create(:user) }

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

        describe 'Project commits' do
          let!(:pipeline_from_other_branch) do
            create(
              :ci_pipeline,
              project: project,
              ref: 'fix',
              sha: project.commit.sha,
              status: :failed
            )
          end

          before do
            visit project_commits_path(project, :master)
          end

          it 'shows correct build status from default branch' do
            page.within("//li[@id='commit-#{pipeline.short_sha}']") do
              expect(page).to have_css("[data-testid='ci-icon']")
              expect(page).to have_css('[data-testid="status_success_borderless-icon"]')
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

        describe 'Cancel all builds' do
          it 'cancels commit', :js, :sidekiq_might_not_need_inline do
            visit pipeline_path(pipeline)
            click_on 'Cancel pipeline'
            expect(page).to have_content 'Canceled'
          end
        end

        describe 'Cancel build' do
          it 'cancels build', :js, :sidekiq_might_not_need_inline do
            visit pipeline_path(pipeline)
            find_by_testid('cancel-pipeline').click
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

      context 'when accessing internal project with disallowed access', :js, quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/299575' do
        before do
          project.update!(
            visibility_level: Gitlab::VisibilityLevel::INTERNAL,
            public_builds: false)
          create(:ci_job_artifact, :archive, file: artifacts_file, job: build)
          visit pipeline_path(pipeline)
        end

        it do
          expect(page).to have_content pipeline.sha[0..7]
          expect(page).to have_content pipeline.git_commit_message.gsub!(/\s+/, ' ')
          expect(page).to have_content pipeline.user.name

          expect(page).not_to have_link('Cancel pipeline')
          expect(page).not_to have_link('Retry')
        end
      end
    end
  end

  context 'viewing commits for a branch' do
    let(:branch_name) { 'master' }
    let(:ref_selector) { '.ref-selector' }
    let(:ref_with_hash) { 'ref-#-hash' }

    def switch_ref_to(ref_name)
      first(ref_selector).click
      wait_for_requests

      page.within ref_selector do
        fill_in 'Search by Git revision', with: ref_name
        wait_for_requests
        find('li', text: ref_name, match: :prefer_exact).click
      end
    end

    before do
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

  context 'viewing commits for an author' do
    let(:author_commit) { project.repository.commits(nil, limit: 1).first }
    let(:commits) { project.repository.commits(nil, author: author, limit: 40) }

    before do
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
end
