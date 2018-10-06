require 'rails_helper'

describe 'Merge request > Batch comments', :js do
  include MergeRequestDiffHelpers
  include RepoHelpers

  let(:user) { create(:user) }
  let(:project) { create(:project, :repository) }
  let(:merge_request) do
    create(:merge_request_with_diffs, source_project: project, target_project: project, source_branch: 'merge-test')
  end

  before do
    project.add_maintainer(user)

    sign_in(user)
  end

  context 'Feature is disabled' do
    before do
      stub_feature_flags(batch_comments: false)

      visit_diffs
    end

    it 'does not have review bar' do
      expect(page).not_to have_css('.review-bar-component')
    end
  end

  context 'Feature is enabled' do
    before do
      stub_licensed_features(batch_comments: true)

      visit_diffs
    end

    it 'has review bar' do
      expect(page).to have_css('.review-bar-component', visible: false)
    end

    it 'adds draft note' do
      write_comment

      expect(find('.draft-note-component')).to have_content('Line is wrong')

      expect(page).to have_css('.review-bar-component')

      expect(find('.review-bar-content .btn-success')).to have_content('1')
    end

    it 'publishes review' do
      write_comment

      page.within('.review-bar-content') do
        click_button 'Submit review'
      end

      wait_for_requests

      expect(page).not_to have_selector('.draft-note-component', text: 'Line is wrong')

      expect(page).to have_selector('.note:not(.draft-note)', text: 'Line is wrong')
    end

    it 'publishes single comment' do
      write_comment

      click_button 'Add comment now'

      wait_for_requests

      expect(page).not_to have_selector('.draft-note-component', text: 'Line is wrong')

      expect(page).to have_selector('.note:not(.draft-note)', text: 'Line is wrong')
    end

    it 'discards review' do
      write_comment

      click_button 'Discard review'

      click_button 'Delete all pending comments'

      wait_for_requests

      expect(page).not_to have_selector('.draft-note-component')
    end

    it 'deletes draft note' do
      write_comment

      accept_alert { find('.js-note-delete').click }

      wait_for_requests

      expect(page).not_to have_selector('.draft-note-component', text: 'Line is wrong')
    end

    it 'edits draft note' do
      write_comment

      find('.js-note-edit').click

      # make sure comment form is in view
      execute_script("window.scrollBy(0, 200)")

      page.within('.js-discussion-note-form') do
        fill_in('note_note', with: 'Testing update')
        click_button('Save comment')
      end

      wait_for_requests

      expect(page).to have_selector('.draft-note-component', text: 'Testing update')
    end

    context 'in parallel diff' do
      before do
        click_button 'Side-by-side'
      end

      it 'adds draft comments to both sides' do
        write_parallel_comment('2f6fcd96b88b36ce98c38da085c795a27d92a3dd_10_9')
        write_parallel_comment('2f6fcd96b88b36ce98c38da085c795a27d92a3dd_9_9', button_text: 'Add to review', text: 'Another wrong line')

        expect(find('.new .draft-note-component')).to have_content('Line is wrong')
        expect(find('.old .draft-note-component')).to have_content('Another wrong line')

        expect(find('.review-bar-content .btn-success')).to have_content('2')
      end
    end
  end

  def visit_diffs
    visit diffs_project_merge_request_path(merge_request.project, merge_request)

    wait_for_requests
  end

  def write_comment(button_text: 'Start a review', text: 'Line is wrong')
    click_diff_line(find("[id='#{sample_compare.changes[0][:line_code]}']"))

    page.within('.js-discussion-note-form') do
      fill_in('note_note', with: text)
      click_button(button_text)
    end

    wait_for_requests
  end

  def write_parallel_comment(line, button_text: 'Start a review', text: 'Line is wrong')
    find("td[id='#{line}']").hover
    find(".is-over button").click

    page.within("form[data-line-code='#{line}']") do
      fill_in('note_note', with: text)
      click_button(button_text)
    end

    wait_for_requests
  end
end
