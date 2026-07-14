# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Projects > Show > Content display', feature_category: :groups_and_projects do
  describe 'README' do
    let_it_be(:project) { create(:project, :repository, :public) }

    it 'shows the project README', :js do
      visit project_path(project)
      wait_for_requests

      page.within('.readme-holder') do
        expect(page).to have_content 'testme'
      end
    end

    context 'obeying robots.txt' do
      before do
        Gitlab::Testing::RobotsBlockerMiddleware.block_requests!
      end

      after do
        Gitlab::Testing::RobotsBlockerMiddleware.allow_requests!
      end

      # For example, see this regression we had in
      # https://gitlab.com/gitlab-org/gitlab/-/merge_requests/39520
      it 'does not block the requests necessary to load the project README', :js do
        visit project_path(project)
        wait_for_requests

        page.within('.readme-holder') do
          expect(page).to have_content 'testme'
        end
      end
    end
  end

  describe 'Schema markup' do
    let_it_be(:project) { create(:project, :repository, :public, :with_avatar, description: 'foobar', topic_list: 'topic1, topic2') }

    it 'shows SoftwareSourceCode structured markup', :js do
      visit project_path(project)
      wait_for_all_requests

      aggregate_failures do
        expect(page).to have_selector('[itemscope][itemtype="http://schema.org/SoftwareSourceCode"]')
        expect(page).to have_selector('img[itemprop="image"]')
        expect(page).to have_selector('[itemprop="name"]', text: project.name)
        expect(page).to have_selector('[itemprop="identifier"]', text: "Project ID: #{project.id}")
        expect(page).to have_selector('[itemprop="description"]', text: project.description)
        expect(page).to have_selector('[itemprop="license"]', text: project.repository.license.name)
        expect(find_all('[itemprop="keywords"]').map(&:text)).to match_array(project.topic_list)
        expect(page).to have_selector('[itemprop="about"]')
      end
    end
  end

  describe 'Last commit CI status' do
    let_it_be_with_reload(:project) { create(:project, :repository, :public) }

    it 'shows the last commit CI status', :js, :aggregate_failures do
      project.enable_ci
      pipeline = create(:ci_pipeline, project: project, sha: project.commit.sha, ref: 'master')
      pipeline.skip

      visit project_path(project)

      page.within '.commit-detail' do
        expect(page).to have_content(project.commit.sha[0..6])
        expect(page).to have_selector('[aria-label="Status: Skipped"]')
      end
    end
  end

  describe 'Deletion failure message' do
    let(:project) { create(:project, :empty_repo, pending_delete: true) }

    before do
      sign_in(project.first_owner)
    end

    it 'shows error message if deletion for project fails', :aggregate_failures do
      project.deletion_error = "Something went wrong"
      project.project_namespace.namespace_details.save!
      project.update!(pending_delete: false)

      visit project_path(project)

      expect(page).to have_selector('.project-deletion-failed-message')
      expect(page).to have_content("This project was scheduled for deletion, but failed with the following message: #{project.deletion_error}")
    end
  end

  describe 'RSS' do
    let(:user) { create(:user) }
    let(:project) { create(:project, :repository, :public) }
    let(:path) { project_path(project) }

    context 'when signed in' do
      before do
        project.add_developer(user)
        sign_in(user)
        visit path
      end

      it_behaves_like "an autodiscoverable RSS feed with current_user's feed token"
    end

    context 'when signed out' do
      before do
        visit path
      end

      it_behaves_like "an autodiscoverable RSS feed without a feed token"
    end
  end
end
