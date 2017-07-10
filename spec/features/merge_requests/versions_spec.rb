require 'spec_helper'

feature 'Merge Request versions', js: true, feature: true do
  let(:merge_request) { create(:merge_request, importing: true) }
  let(:project) { merge_request.source_project }
  let!(:merge_request_diff1) { merge_request.merge_request_diffs.create(head_commit_sha: '6f6d7e7ed97bb5f0054f2b1df789b39ca89b6ff9') }
  let!(:merge_request_diff2) { merge_request.merge_request_diffs.create(head_commit_sha: nil) }
  let!(:merge_request_diff3) { merge_request.merge_request_diffs.create(head_commit_sha: '5937ac0a7beb003549fc5fd26fc247adbce4a52e') }

  before do
    sign_in(create(:admin))
    visit diffs_project_merge_request_path(project, merge_request)
  end

  it 'show the latest version of the diff' do
    page.within '.mr-version-dropdown' do
      expect(page).to have_content 'latest version'
    end

    expect(page).to have_content '8 changed files'
  end

  describe 'switch between versions' do
    before do
      page.within '.mr-version-dropdown' do
        find('.btn-default').click
        click_link 'version 1'
      end

      # Wait for the page to load
      page.within '.mr-version-dropdown' do
        expect(page).to have_content 'version 1'
      end
    end

    it 'should show older version' do
      page.within '.mr-version-dropdown' do
        expect(page).to have_content 'version 1'
      end

      expect(page).to have_content '5 changed files'
    end

    it 'show the message about comments' do
      expect(page).to have_content 'Not all comments are displayed'
    end

    it 'shows comments that were last relevant at that version' do
      position = Gitlab::Diff::Position.new(
        old_path: ".gitmodules",
        new_path: ".gitmodules",
        old_line: nil,
        new_line: 4,
        diff_refs: merge_request_diff1.diff_refs
      )
      outdated_diff_note = create(:diff_note_on_merge_request, project: project, noteable: merge_request, position: position)
      outdated_diff_note.position = outdated_diff_note.original_position
      outdated_diff_note.save!

      visit current_url

      expect(page).to have_css(".diffs .notes[data-discussion-id='#{outdated_diff_note.discussion_id}']")
    end

    it 'allows commenting' do
      diff_file_selector = ".diff-file[id='7445606fbf8f3683cd42bdc54b05d7a0bc2dfc44']"
      line_code = '7445606fbf8f3683cd42bdc54b05d7a0bc2dfc44_2_2'

      page.within(diff_file_selector) do
        find(".line_holder[id='#{line_code}'] td:nth-of-type(1)").trigger 'mouseover'
        find(".line_holder[id='#{line_code}'] button").trigger 'click'

        page.within("form[data-line-code='#{line_code}']") do
          fill_in "note[note]", with: "Typo, please fix"
          find(".js-comment-button").click
        end

        wait_for_requests

        expect(page).to have_content("Typo, please fix")
      end
    end
  end

  describe 'compare with older version' do
    before do
      page.within '.mr-version-compare-dropdown' do
        find('.btn-default').click
        click_link 'version 1'
      end

      # Wait for the page to load
      page.within '.mr-version-compare-dropdown' do
        expect(page).to have_content 'version 1'
      end
    end

    it 'has a path with comparison context' do
      expect(page).to have_current_path diffs_project_merge_request_path(
        project,
        merge_request.iid,
        diff_id: merge_request_diff3.id,
        start_sha: '6f6d7e7ed97bb5f0054f2b1df789b39ca89b6ff9'
      )
    end

    it 'should have correct value in the compare dropdown' do
      page.within '.mr-version-compare-dropdown' do
        expect(page).to have_content 'version 1'
      end
    end

    it 'show the message about comments' do
      expect(page).to have_content 'Not all comments are displayed'
    end

    it 'shows comments that were last relevant at that version' do
      position = Gitlab::Diff::Position.new(
        old_path: ".gitmodules",
        new_path: ".gitmodules",
        old_line: 4,
        new_line: 4,
        diff_refs: merge_request_diff3.compare_with(merge_request_diff1.head_commit_sha).diff_refs
      )
      outdated_diff_note = create(:diff_note_on_merge_request, project: project, noteable: merge_request, position: position)
      outdated_diff_note.position = outdated_diff_note.original_position
      outdated_diff_note.save!

      visit current_url
      wait_for_requests

      expect(page).to have_css(".diffs .notes[data-discussion-id='#{outdated_diff_note.discussion_id}']")
    end

    it 'allows commenting' do
      diff_file_selector = ".diff-file[id='7445606fbf8f3683cd42bdc54b05d7a0bc2dfc44']"
      line_code = '7445606fbf8f3683cd42bdc54b05d7a0bc2dfc44_4_4'

      page.within(diff_file_selector) do
        find(".line_holder[id='#{line_code}'] td:nth-of-type(1)").trigger 'mouseover'
        find(".line_holder[id='#{line_code}'] button").trigger 'click'

        page.within("form[data-line-code='#{line_code}']") do
          fill_in "note[note]", with: "Typo, please fix"
          find(".js-comment-button").click
        end

        wait_for_requests

        expect(page).to have_content("Typo, please fix")
      end
    end

    it 'show diff between new and old version' do
      expect(page).to have_content '4 changed files with 15 additions and 6 deletions'
    end

    it 'should return to latest version when "Show latest version" button is clicked' do
      click_link 'Show latest version'
      page.within '.mr-version-dropdown' do
        expect(page).to have_content 'latest version'
      end
      expect(page).to have_content '8 changed files'
    end
  end

  describe 'compare with same version' do
    before do
      page.within '.mr-version-compare-dropdown' do
        find('.btn-default').click
        click_link 'version 1'
      end
    end

    it 'should have 0 chages between versions' do
      page.within '.mr-version-compare-dropdown' do
        expect(find('.dropdown-toggle')).to have_content 'version 1'
      end

      page.within '.mr-version-dropdown' do
        find('.btn-default').click
        click_link 'version 1'
      end
      expect(page).to have_content '0 changed files'
    end
  end

  describe 'compare with newer version' do
    before do
      page.within '.mr-version-compare-dropdown' do
        find('.btn-default').click
        click_link 'version 2'
      end
    end

    it 'should set the compared versions to be the same' do
      page.within '.mr-version-compare-dropdown' do
        expect(find('.dropdown-toggle')).to have_content 'version 2'
      end

      page.within '.mr-version-dropdown' do
        find('.btn-default').click
        click_link 'version 1'
      end

      page.within '.mr-version-compare-dropdown' do
        expect(page).to have_content 'version 1'
      end

      expect(page).to have_content '0 changed files'
    end
  end
end
