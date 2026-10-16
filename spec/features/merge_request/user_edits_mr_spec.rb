# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Merge request > User edits MR', feature_category: :code_review_workflow do
  include ProjectForksHelper

  shared_examples 'an editable merge request with visible selected labels' do
    it 'updates merge request', :js do
      find('.js-assignee-search').click
      page.within '.dropdown-menu-user' do
        click_link user.name
      end
      expect(find('input[name="merge_request[assignee_ids][]"]', visible: false).value).to match(user.id.to_s)
      page.within '.js-assignee-search' do
        expect(page).to have_content user.name
      end

      find('.js-reviewer-search').click
      page.within '.dropdown-menu-user' do
        click_link user.name
      end
      expect(find('input[name="merge_request[reviewer_ids][]"]', visible: false).value).to match(user.id.to_s)
      page.within '.js-reviewer-search' do
        expect(page).to have_content user.name
      end

      click_button 'Select milestone'
      click_button milestone.title
      expect(find('input[name="merge_request[milestone_id]"]', visible: false).value).to match(milestone.id.to_s)
      expect(page).to have_button milestone.title

      click_button _('Select label')
      wait_for_all_requests
      within_testid('sidebar-labels') do
        click_button label.title
        click_button label2.title
        click_button _('Close')
        wait_for_requests
        within_testid('embedded-labels-list') do
          expect(page).to have_content(label.title)
          expect(page).to have_content(label2.title)
        end
      end

      click_button 'Save changes'

      page.within '.issuable-sidebar' do
        page.within '.assignee' do
          expect(page).to have_content user.name
        end

        page.within '.reviewer' do
          expect(page).to have_content user.name
        end

        page.within '.milestone' do
          expect(page).to have_content milestone.title
        end

        page.within '.labels' do
          expect(page).to have_content label.title
          expect(page).to have_content label2.title
        end
      end
    end

    it 'description has autocomplete', :js do
      find('#merge_request_description').native.send_keys('')
      fill_in 'merge_request_description', with: user.to_reference[0..4]

      page.within('.atwho-view') do
        expect(page).to have_content(user2.name)
      end
    end

    it 'description has quick action autocomplete', :js do
      find('#merge_request_description').native.send_keys('/')

      expect(page).to have_selector('.atwho-container')
    end

    it 'has class js-quick-submit in form' do
      expect(page).to have_selector('.js-quick-submit')
    end

    it 'warns about version conflict', :js do
      merge_request.update!(title: "New title")

      fill_in 'merge_request_title', with: 'bug 345'
      fill_in 'merge_request_description', with: 'bug description'

      click_button _('Save changes')

      expect(page).to have_content(
        format(
          _("Someone edited this %{model_name} at the same time you did. Please check out the %{link_to_model} and make sure your changes will not unintentionally remove theirs."),
          model_name: _('merge request'),
          link_to_model: _('merge request')
        )
      )
    end

    it 'preserves description textarea height', :js do
      long_description = (1..30).map { |i| "Line #{i}" }.join("\n")

      fill_in 'merge_request_description', with: long_description

      height = get_textarea_height
      click_button("Preview")
      click_button("Continue editing")
      new_height = get_textarea_height

      expect(height).to eq(new_height)
    end

    context 'when "Remove source branch" is set' do
      before do
        merge_request.update!(merge_params: { 'force_remove_source_branch' => '1' })
      end

      it 'allows to unselect "Remove source branch"', :js do
        expect(merge_request.merge_params['force_remove_source_branch']).to be_truthy

        uncheck 'Delete source branch when merge request is accepted'

        click_button 'Save changes'

        expect(page).to have_unchecked_field 'remove-source-branch-input'
        expect(page).to have_content 'Delete source branch'
      end
    end
  end

  before do
    stub_licensed_features(multiple_merge_request_assignees: false)
  end

  context 'non-fork merge request' do
    include_context 'merge request edit context'
    it_behaves_like 'an editable merge request with visible selected labels'
  end

  context 'for a forked project' do
    let(:source_project) { fork_project(target_project, nil, repository: true) }

    include_context 'merge request edit context'
    it_behaves_like 'an editable merge request with visible selected labels'
  end
end
