require 'spec_helper'

describe 'Commits' do
  include CiStatusHelper

  let(:project) { create(:project) }

  describe 'CI' do
    before do
      login_as :user
      stub_ci_commit_to_return_yaml_file
    end

    let!(:commit) do
      FactoryGirl.create :ci_commit, project: project, sha: project.commit.sha
    end

    context 'commit status is Generic Commit Status' do
      let!(:status) { FactoryGirl.create :generic_commit_status, commit: commit }

      before do
        project.team << [@user, :reporter]
      end

      describe 'Commit builds' do
        before do
          visit ci_status_path(commit)
        end

        it { expect(page).to have_content commit.sha[0..7] }

        it 'contains generic commit status build' do
          page.within('.table-holder') do
            expect(page).to have_content "##{status.id}" # build id
            expect(page).to have_content 'generic'       # build name
          end
        end
      end
    end

    context 'commit status is Ci Build' do
      let!(:build) { FactoryGirl.create :ci_build, commit: commit }
      let(:artifacts_file) { fixture_file_upload(Rails.root + 'spec/fixtures/banana_sample.gif', 'image/gif') }

      context 'when logged as developer' do
        before do
          project.team << [@user, :developer]
        end

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

      context "when logged as reporter" do
        before do
          project.team << [@user, :reporter]
          build.update_attributes(artifacts_file: artifacts_file)
          visit ci_status_path(commit)
        end

        it do
          expect(page).to have_content commit.sha[0..7]
          expect(page).to have_content commit.git_commit_message
          expect(page).to have_content commit.git_author_name
          expect(page).to have_link('Download artifacts')
          expect(page).to_not have_link('Cancel running')
          expect(page).to_not have_link('Retry failed')
        end
      end

      context 'when accessing internal project with disallowed access' do
        before do
          project.update(
            visibility_level: Gitlab::VisibilityLevel::INTERNAL,
            public_builds: false)
          build.update_attributes(artifacts_file: artifacts_file)
          visit ci_status_path(commit)
        end

        it do
          expect(page).to have_content commit.sha[0..7]
          expect(page).to have_content commit.git_commit_message
          expect(page).to have_content commit.git_author_name
          expect(page).to_not have_link('Download artifacts')
          expect(page).to_not have_link('Cancel running')
          expect(page).to_not have_link('Retry failed')
        end
      end
    end
  end
end
