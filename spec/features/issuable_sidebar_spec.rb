require 'spec_helper'

feature 'Issuable sidebar', feature: true do
  include SortingHelper

  let(:project) { create(:project) }
  let!(:user)   { create(:user)}
  let(:merge_request) { create(:merge_request, :with_diffs, source_project: project) }

  before do
    project.team << [user, :master]

    login_as user

    visit namespace_project_merge_request_path(project.namespace, project, merge_request)
  end

  context 'changing tabs', js: true do

    context 'between commits and changes for md' do

      before do
        page.driver.browser.resize(1024, 600)
      end

      it 'should show the right sidebar on commits tab' do
        page.find('.commits-tab').click

        expect(page).to have_selector('.right-sidebar-expanded')
      end

      it 'should collapse the right sidebar on changes tab' do
        page.find('.diffs-tab').click

        expect(page).to have_selector('.right-sidebar-collapsed')
      end
    end

    context 'between discussion and changes for md' do

      before do
        page.driver.browser.resize(1024, 600)
      end

      it 'should show the right sidebar on discussion tab' do
        page.find('.notes-tab').click

        expect(page).to have_selector('.right-sidebar-expanded')
      end

      it 'should collapse the right sidebar on commits tab' do
        page.find('.diffs-tab').click

        expect(page).to have_selector('.right-sidebar-collapsed')
      end
    end

    context 'when user collapse right sidebar for md' do

      before do
        page.driver.browser.resize(1024, 600)

        page.find('.js-sidebar-toggle').click
      end

      it 'should not show the right sidebar on commits tab' do
        page.find('.notes-tab').click

        expect(page).to have_selector('.right-sidebar-collapsed')
      end

      it 'should not show the right sidebar on changes tab' do
        page.find('.diffs-tab').click

        expect(page).to have_selector('.right-sidebar-collapsed')
      end
    end

    context 'between commits and changes for lg' do

      before do
        page.driver.browser.resize(1440, 600)
      end

      it 'should show the right sidebar on commits tab' do
        page.find('.commits-tab').click

        expect(page).to have_selector('.right-sidebar-expanded')
      end

      it 'should not collapse the right sidebar on changes tab' do
        page.find('.diffs-tab').click

        expect(page).to have_selector('.right-sidebar-expanded')
      end
    end

    context 'between discussion and changes for lg' do

      before do
        page.driver.browser.resize(1440, 600)
      end

      it 'should show the right sidebar on discussion tab' do
        page.find('.notes-tab').click

        expect(page).to have_selector('.right-sidebar-expanded')
      end

      it 'should not collapse the right sidebar on commits tab' do
        page.find('.diffs-tab').click

        expect(page).to have_selector('.right-sidebar-expanded')
      end
    end
  end
end
