require 'spec_helper'

describe 'Issuables Close/Reopen/Report toggle' do
  let(:user) { create(:user) }

  shared_examples 'an issuable close/reopen/report toggle' do
    let(:container) { find('.issuable-close-dropdown') }
    let(:human_model_name) { issuable.model_name.human.downcase }

    it 'shows toggle' do
      expect(page).to have_link("Close #{human_model_name}")
      expect(page).to have_selector('.issuable-close-dropdown')
    end

    it 'opens a dropdown when toggle is clicked' do
      container.find('.dropdown-toggle').click

      expect(container).to have_selector('.dropdown-menu')
      expect(container).to have_content("Close #{human_model_name}")
      expect(container).to have_content('Report abuse')
      expect(container).to have_content("Report #{human_model_name.pluralize} that are abusive, inappropriate or spam.")
      expect(container).to have_selector('.close-item.droplab-item-selected')
      expect(container).to have_selector('.report-item')
      expect(container).not_to have_selector('.report-item.droplab-item-selected')
      expect(container).not_to have_selector('.reopen-item')
    end

    it 'changes the button when an item is selected' do
      button = container.find('.issuable-close-button')

      container.find('.dropdown-toggle').click
      container.find('.report-item').click

      expect(container).not_to have_selector('.dropdown-menu')
      expect(button).to have_content('Report abuse')

      container.find('.dropdown-toggle').click
      container.find('.close-item').click

      expect(button).to have_content("Close #{human_model_name}")
    end
  end

  context 'on an issue' do
    let(:project) { create(:project) }
    let(:issuable) { create(:issue, project: project) }

    before do
      project.add_master(user)
      login_as user
    end

    context 'when user has permission to update', :js do
      before do
        visit project_issue_path(project, issuable)
      end

      it_behaves_like 'an issuable close/reopen/report toggle'
    end

    context 'when user doesnt have permission to update' do
      let(:cant_project) { create(:project) }
      let(:cant_issuable) { create(:issue, project: cant_project) }

      before do
        cant_project.add_guest(user)

        visit project_issue_path(cant_project, cant_issuable)
      end

      it 'only shows the `Report abuse` and `New issue` buttons' do
        expect(page).to have_link('Report abuse')
        expect(page).to have_link('New issue')
        expect(page).not_to have_link('Close issue')
        expect(page).not_to have_link('Reopen issue')
        expect(page).not_to have_link('Edit')
      end
    end
  end

  context 'on a merge request' do
    let(:project) { create(:project, :repository) }
    let(:issuable) { create(:merge_request, source_project: project) }

    before do
      project.add_master(user)
      login_as user
    end

    context 'when user has permission to update', :js do
      before do
        visit project_merge_request_path(project, issuable)
      end

      it_behaves_like 'an issuable close/reopen/report toggle'
    end

    context 'when user doesnt have permission to update' do
      let(:cant_project) { create(:project, :repository) }
      let(:cant_issuable) { create(:merge_request, source_project: cant_project) }

      before do
        cant_project.add_reporter(user)

        visit project_merge_request_path(cant_project, cant_issuable)
      end

      it 'only shows a `Report abuse` button' do
        expect(page).to have_link('Report abuse')
        expect(page).not_to have_link('Close merge request')
        expect(page).not_to have_link('Reopen merge request')
        expect(page).not_to have_link('Edit')
      end
    end
  end
end
