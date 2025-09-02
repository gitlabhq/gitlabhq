# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User creates branch and merge request on issue page', :js, feature_category: :team_planning do
  include Spec::Support::Helpers::ModalHelpers

  let(:membership_level) { :developer }
  let(:user) { create(:user) }
  let!(:project) { create(:project, :repository, :public) }
  let(:issue) { create(:issue, project: project, title: 'Cherry-Coloured Funk') }

  before do
    stub_feature_flags(work_item_view_for_issues: true)
  end

  context 'when signed out' do
    before do
      visit project_issue_path(project, issue)
    end

    it "doesn't show 'Create merge request' button" do
      expect(page).not_to have_button 'Create merge request'
    end
  end

  context 'when signed in' do
    before do
      project.add_member(user, membership_level)

      sign_in(user)
    end

    context 'when interacting with the dropdown' do
      before do
        visit project_issue_path(project, issue)
      end

      it 'shows elements' do
        within_testid('create-options-dropdown') do
          click_button "More options"

          expect(page).to have_button('Create merge request')
          expect(page).to have_button('Create branch')

          click_button 'Create branch'
        end

        within_modal do
          expect(page).to have_field('Source (branch or tag)', with: project.default_branch)
          expect(page).to have_field('Branch name', with: issue.to_branch_name)

          fill_in 'Source (branch or tag)', with: 'mas'

          expect(page).to have_text('Source is not available')

          fill_in 'Branch name', with: 'new-branch-name'

          expect(page).to have_text('Branch name is available')

          fill_in 'Branch name', with: project.default_branch

          expect(page).to have_text('Branch is already taken')
          # The button inside dropdown should be disabled if any errors occurred.
          expect(page).to have_button('Create branch', disabled: true)
        end
      end

      context 'when branch name is auto-generated' do
        it 'creates a merge request' do
          perform_enqueued_jobs do
            click_button 'Create merge request'
            within_modal do
              click_button 'Create merge request'
            end

            expect(page).to have_css('h1', text: 'New merge request')
            expect(page).to have_text("From #{issue.to_branch_name} into #{project.default_branch}")
            expect(page).to have_field("Title", with: "Draft: Resolve \"Cherry-Coloured Funk\"")
            expect(page).to have_field("Description", with: "Closes ##{issue.iid}")
            expect(page).to have_current_path(project_new_merge_request_path(project, merge_request: { source_branch: issue.to_branch_name, target_branch: project.default_branch, issue_iid: issue.iid }))
          end
        end

        it 'creates a branch' do
          within_testid('create-options-dropdown') do
            click_button "More options"
          end
          click_button 'Create branch'
          within_modal do
            click_button 'Create branch'
          end

          expect(page).to have_css('.gl-toast', text: 'Branch created.')
        end
      end

      context 'when branch name is custom' do
        let(:branch_name) { 'custom-branch-name' }

        it 'creates a merge request' do
          perform_enqueued_jobs do
            click_button 'Create merge request'
            within_modal do
              fill_in 'Branch name', with: branch_name
              click_button 'Create merge request'
            end

            expect(page).to have_css('h1', text: 'New merge request')
            expect(page).to have_text("From #{branch_name} into #{project.default_branch}")
            expect(page).to have_field("Title", with: "Draft: Resolve \"Cherry-Coloured Funk\"")
            expect(page).to have_field("Description", with: "Closes ##{issue.iid}")
            expect(page).to have_current_path(project_new_merge_request_path(project, merge_request: { source_branch: branch_name, target_branch: project.default_branch, issue_iid: issue.iid }))
          end
        end

        it 'creates a branch' do
          within_testid('create-options-dropdown') do
            click_button "More options"
          end
          click_button 'Create branch'
          within_modal do
            fill_in 'Branch name', with: branch_name
            click_button 'Create branch'
          end

          expect(page).to have_css('.gl-toast', text: 'Branch created.')
        end

        context 'when source branch is non-default' do
          let(:source_branch) { 'feature' }

          it 'creates a branch' do
            within_testid('create-options-dropdown') do
              click_button "More options"
            end
            click_button 'Create branch'
            within_modal do
              fill_in 'Source (branch or tag)', with: source_branch
              fill_in 'Branch name', with: branch_name
              click_button 'Create branch'
            end

            expect(page).to have_css('.gl-toast', text: 'Branch created.')
          end
        end
      end

      context 'when branch name is invalid' do
        context 'when creating a merge request' do
          it 'has error message' do
            click_button 'Create merge request'
            within_modal do
              fill_in 'Branch name', with: 'custom-branch-name w~th ^bad chars?'
            end

            expect(page).to have_text("Can't contain spaces, ~, ^, ?")
          end
        end

        context 'when creating a branch' do
          it 'has error message' do
            within_testid('create-options-dropdown') do
              click_button "More options"
            end
            click_button 'Create branch'
            within_modal do
              fill_in 'Branch name', with: 'custom-branch-name w~th ^bad chars?'
            end

            expect(page).to have_text("Can't contain spaces, ~, ^, ?")
          end
        end
      end
    end

    context 'when merge requests are disabled' do
      before do
        project.project_feature.update!(merge_requests_access_level: 0)

        visit project_issue_path(project, issue)
      end

      it 'shows only create branch button' do
        expect(page).not_to have_button('Create merge request')
        expect(page).to have_button('Create branch')
      end
    end

    context 'when related branch exists' do
      let!(:project) { create(:project, :repository, :private) }
      let(:branch_name) { "#{issue.iid}-foo" }

      before do
        stub_feature_flags(work_item_view_for_issues: false)
        project.repository.create_branch(branch_name)

        visit project_issue_path(project, issue)
      end

      context 'when user is developer' do
        it 'shows related branches' do
          within('#related-branches', match: :first) do
            expect(page).to have_link(branch_name)
          end
        end
      end

      context 'when user is guest' do
        let(:membership_level) { :guest }

        it 'does not show related branches' do
          expect(page).not_to have_css('[data-testid="work-item-development"]')
        end
      end
    end
  end
end
