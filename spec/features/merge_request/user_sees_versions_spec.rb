require 'rails_helper'

describe 'Merge request > User sees versions', :js do
  let(:merge_request) { create(:merge_request, importing: true) }
  let(:project) { merge_request.source_project }
  let(:user) { project.creator }
  let!(:merge_request_diff1) { merge_request.merge_request_diffs.create(head_commit_sha: '6f6d7e7ed97bb5f0054f2b1df789b39ca89b6ff9') }
  let!(:merge_request_diff2) { merge_request.merge_request_diffs.create(head_commit_sha: nil) }
  let!(:merge_request_diff3) { merge_request.merge_request_diffs.create(head_commit_sha: '5937ac0a7beb003549fc5fd26fc247adbce4a52e') }
  let!(:params) { {} }

  before do
    project.add_master(user)
    sign_in(user)
    visit diffs_project_merge_request_path(project, merge_request, params)
  end

  shared_examples 'allows commenting' do |file_id:, line_code:, comment:|
    it do
      diff_file_selector = ".diff-file[id='#{file_id}']"
      line_code = "#{file_id}_#{line_code}"

      page.within(diff_file_selector) do
        find(".line_holder[id='#{line_code}'] td:nth-of-type(1)").hover
        find(".line_holder[id='#{line_code}'] button").click

        page.within("form[data-line-code='#{line_code}']") do
          fill_in "note[note]", with: comment
          find(".js-comment-button").click
        end

        wait_for_requests

        expect(page).to have_content(comment)
      end
    end
  end

  describe 'compare with the latest version' do
    it 'show the latest version of the diff' do
      page.within '.mr-version-dropdown' do
        expect(page).to have_content 'latest version'
      end

      expect(page).to have_content '8 changed files'
    end

    it_behaves_like 'allows commenting',
                    file_id: '7445606fbf8f3683cd42bdc54b05d7a0bc2dfc44',
                    line_code: '1_1',
                    comment: 'Typo, please fix.'
  end

  describe 'switch between versions' do
    before do
      page.within '.mr-version-dropdown' do
        find('.btn-secondary').click
        click_link 'version 1'
      end

      # Wait for the page to load
      page.within '.mr-version-dropdown' do
        expect(page).to have_content 'version 1'
      end
    end

    it 'shows comments that were last relevant at that version' do
      expect(page).to have_content '5 changed files'
      expect(page).to have_content 'Not all comments are displayed'

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

      refresh

      expect(page).to have_css(".diffs .notes[data-discussion-id='#{outdated_diff_note.discussion_id}']")
    end

    it_behaves_like 'allows commenting',
                    file_id: '7445606fbf8f3683cd42bdc54b05d7a0bc2dfc44',
                    line_code: '2_2',
                    comment: 'Typo, please fix.'
  end

  describe 'compare with older version' do
    before do
      page.within '.mr-version-compare-dropdown' do
        find('.btn-secondary').click
        click_link 'version 1'
      end

      # Wait for the page to load
      page.within '.mr-version-compare-dropdown' do
        expect(page).to have_content 'version 1'
      end
    end

    it 'has a path with comparison context and shows comments that were last relevant at that version' do
      expect(page).to have_current_path diffs_project_merge_request_path(
        project,
        merge_request.iid,
        diff_id: merge_request_diff3.id,
        start_sha: '6f6d7e7ed97bb5f0054f2b1df789b39ca89b6ff9'
      )
      expect(page).to have_content '4 changed files with 15 additions and 6 deletions'
      expect(page).to have_content 'Not all comments are displayed'

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

      refresh
      wait_for_requests

      expect(page).to have_css(".diffs .notes[data-discussion-id='#{outdated_diff_note.discussion_id}']")
    end

    it 'show diff between new and old version' do
      expect(page).to have_content '4 changed files with 15 additions and 6 deletions'
    end

    it 'returns to latest version when "Show latest version" button is clicked' do
      click_link 'Show latest version'
      page.within '.mr-version-dropdown' do
        expect(page).to have_content 'latest version'
      end
      expect(page).to have_content '8 changed files'
    end

    it_behaves_like 'allows commenting',
                    file_id: '7445606fbf8f3683cd42bdc54b05d7a0bc2dfc44',
                    line_code: '4_4',
                    comment: 'Typo, please fix.'
  end

  describe 'compare with same version' do
    before do
      page.within '.mr-version-compare-dropdown' do
        find('.btn-secondary').click
        click_link 'version 1'
      end
    end

    it 'has 0 chages between versions' do
      page.within '.mr-version-compare-dropdown' do
        expect(find('.dropdown-toggle')).to have_content 'version 1'
      end

      page.within '.mr-version-dropdown' do
        find('.btn-secondary').click
        click_link 'version 1'
      end
      expect(page).to have_content '0 changed files'
    end
  end

  describe 'compare with newer version' do
    before do
      page.within '.mr-version-compare-dropdown' do
        find('.btn-secondary').click
        click_link 'version 2'
      end
    end

    it 'sets the compared versions to be the same' do
      page.within '.mr-version-compare-dropdown' do
        expect(find('.dropdown-toggle')).to have_content 'version 2'
      end

      page.within '.mr-version-dropdown' do
        find('.btn-secondary').click
        click_link 'version 1'
      end

      page.within '.mr-version-compare-dropdown' do
        expect(page).to have_content 'version 1'
      end

      expect(page).to have_content '0 changed files'
    end
  end

  describe 'scoped in a commit' do
    let(:params) { { commit_id: '570e7b2abdd848b95f2f578043fc23bd6f6fd24d' } }

    before do
      wait_for_requests
    end

    it 'should only show diffs from the commit' do
      diff_commit_ids = find_all('.diff-file [data-commit-id]').map {|diff| diff['data-commit-id']}

      expect(diff_commit_ids).not_to be_empty
      expect(diff_commit_ids).to all(eq(params[:commit_id]))
    end

    it_behaves_like 'allows commenting',
                    file_id: '2f6fcd96b88b36ce98c38da085c795a27d92a3dd',
                    line_code: '6_6',
                    comment: 'Typo, please fix.'
  end
end
