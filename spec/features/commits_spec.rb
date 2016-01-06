require 'spec_helper'

describe 'Commits' do
  include CiStatusHelper

  let(:project) { create(:project) }

  describe 'CI' do
    before do
      login_as :user
      project.team << [@user, :master]
      stub_ci_commit_to_return_yaml_file
    end

    let!(:commit) do
      FactoryGirl.create :ci_commit, project: project, sha: project.commit.sha
    end

    let!(:build) { FactoryGirl.create :ci_build, commit: commit }

    describe 'Project commits' do
      before do
        visit namespace_project_commits_path(project.namespace, project, :master)
      end

      it 'should show build status' do
        page.within("//li[@id='commit-#{commit.short_sha}']") do
          expect(page).to have_css(".ci-status-link")
        end
      end
    end

    describe 'Commit builds' do
      before do
        visit ci_status_path(commit)
      end

      it { expect(page).to have_content commit.sha[0..7] }
      it { expect(page).to have_content commit.git_commit_message }
      it { expect(page).to have_content commit.git_author_name }
    end

    context 'Download artifacts' do
      let(:artifacts_file) { fixture_file_upload(Rails.root + 'spec/fixtures/banana_sample.gif', 'image/gif') }

      before do
        build.update_attributes(artifacts_file: artifacts_file)
      end

      it do
        visit ci_status_path(commit)
        click_on 'Download artifacts'
        expect(page.response_headers['Content-Type']).to eq(artifacts_file.content_type)
      end
    end

    describe 'Cancel all builds' do
      it 'cancels commit' do
        visit ci_status_path(commit)
        click_on 'Cancel running'
        expect(page).to have_content 'canceled'
      end
    end

    describe 'Cancel build' do
      it 'cancels build' do
        visit ci_status_path(commit)
        click_on 'Cancel'
        expect(page).to have_content 'canceled'
      end
    end

    describe '.gitlab-ci.yml not found warning' do
      context 'ci builds enabled' do
        it "does not show warning" do
          visit ci_status_path(commit)
          expect(page).not_to have_content '.gitlab-ci.yml not found in this commit'
        end

        it 'shows warning' do
          stub_ci_commit_yaml_file(nil)
          visit ci_status_path(commit)
          expect(page).to have_content '.gitlab-ci.yml not found in this commit'
        end
      end

      context 'ci builds disabled' do
        before do
          stub_ci_builds_disabled
          stub_ci_commit_yaml_file(nil)
          visit ci_status_path(commit)
        end

        it 'does not show warning' do
          expect(page).not_to have_content '.gitlab-ci.yml not found in this commit'
        end
      end
    end
  end
end
