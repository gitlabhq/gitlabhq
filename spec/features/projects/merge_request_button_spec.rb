# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Merge Request button', feature_category: :groups_and_projects do
  include ProjectForksHelper

  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :public, :repository) }

  let(:forked_project) { fork_project(project, user, repository: true) }

  shared_examples 'Merge request button only shown when allowed' do
    let(:extra_mr_params) { {} }

    context 'not logged in' do
      it 'does not show Create merge request button' do
        visit url

        within '.content-wrapper' do
          expect(page).not_to have_link(label)
        end
      end
    end

    context 'logged in as developer' do
      before do
        sign_in(user)
        project.add_developer(user)
      end

      it 'shows Create merge request button', :js do
        href = project_new_merge_request_path(
          project,
          merge_request: {
            source_branch: 'feature'
          }.merge(extra_mr_params)
        )

        visit url

        within('#content-body') do
          expect(page).to have_link(label, href: href)
        end
      end

      context 'merge requests are disabled' do
        before do
          project.project_feature.update!(merge_requests_access_level: ProjectFeature::DISABLED)
        end

        it 'does not show Create merge request button' do
          href = project_new_merge_request_path(
            project,
            merge_request: {
              source_branch: 'feature'
            }.merge(extra_mr_params)
          )

          visit url

          within('#content-body') do
            expect(page).not_to have_link(label, href: href)
          end
        end
      end

      context 'when the project is archived' do
        it 'hides the link' do
          project.update!(archived: true)

          visit url

          within("#content-body") do
            expect(page).not_to have_link(label)
          end
        end
      end
    end

    context 'logged in as non-member' do
      before do
        sign_in(user)
      end

      it 'does not show Create merge request button' do
        visit url

        within('#content-body') do
          expect(page).not_to have_link(label)
        end
      end

      context 'on own fork of project' do
        it 'shows Create merge request button', :js do
          href = project_new_merge_request_path(
            forked_project,
            merge_request: {
              source_branch: 'feature'
            }.merge(extra_mr_params)
          )

          visit fork_url

          within("#content-body") do
            expect(page).to have_link(label, href: href)
          end
        end
      end
    end
  end

  context 'on branches page' do
    it_behaves_like 'Merge request button only shown when allowed' do
      let(:label) { 'New' }
      let(:url) { project_branches_filtered_path(project, state: 'all', search: 'feature') }
      let(:fork_url) { project_branches_filtered_path(forked_project, state: 'all', search: 'feature') }
    end
  end

  context 'on compare page' do
    let(:label) { 'Create merge request' }

    it_behaves_like 'Merge request button only shown when allowed' do
      let(:url) { project_compare_path(project, from: 'master', to: 'feature') }
      let(:fork_url) { project_compare_path(forked_project, from: 'master', to: 'feature') }
      let(:extra_mr_params) { { target_project_id: project.id, target_branch: 'master' } }
    end

    it 'shows the correct merge request button when viewing across forks', :js do
      sign_in(user)
      project.add_developer(user)

      href = project_new_merge_request_path(
        forked_project,
        merge_request: {
          source_branch: 'feature',
          target_project_id: project.id,
          target_branch: 'master'
        }
      )

      visit project_compare_path(forked_project, from: 'master', to: 'feature', from_project_id: project.id)

      within("#content-body") do
        expect(page).to have_link(label, href: href)
      end
    end
  end

  context 'on commits page' do
    it_behaves_like 'Merge request button only shown when allowed' do
      let(:label) { 'Create merge request' }
      let(:url) { project_commits_path(project, 'feature') }
      let(:fork_url) { project_commits_path(forked_project, 'feature') }
    end
  end
end
