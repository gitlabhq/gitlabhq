# frozen_string_literal: true

require 'spec_helper'

describe 'Merge request > User resolves diff notes and threads', :js do
  let(:project)       { create(:project, :public, :repository) }
  let(:user)          { project.creator }
  let(:guest)         { create(:user) }
  let(:merge_request) { create(:merge_request_with_diffs, source_project: project, author: user, title: "Bug NS-04") }
  let!(:note)         { create(:diff_note_on_merge_request, project: project, noteable: merge_request, note: "| Markdown | Table |\n|-------|---------|\n| first | second |") }
  let(:path)          { "files/ruby/popen.rb" }
  let(:position) do
    Gitlab::Diff::Position.new(
      old_path: path,
      new_path: path,
      old_line: nil,
      new_line: 9,
      diff_refs: merge_request.diff_refs
    )
  end

  before do
    stub_feature_flags(single_mr_diff_view: false)
    stub_feature_flags(diffs_batch_load: false)
  end

  it_behaves_like 'rendering a single diff version'

  context 'no threads' do
    before do
      project.add_maintainer(user)
      sign_in(user)
      note.destroy
      visit_merge_request
    end

    it 'displays no thread resolved data' do
      expect(page).not_to have_content('thread resolved')
      expect(page).not_to have_selector('.discussion-next-btn')
    end
  end

  context 'as authorized user' do
    before do
      project.add_maintainer(user)
      sign_in(user)
      visit_merge_request
    end

    context 'single thread' do
      it 'shows text with how many threads' do
        page.within '.line-resolve-all-container' do
          expect(page).to have_content('0/1 thread resolved')
        end
      end

      it 'allows user to mark a note as resolved' do
        page.within '.diff-content .note' do
          find('.line-resolve-btn').click

          expect(page).to have_selector('.line-resolve-btn.is-active')
          expect(find('.line-resolve-btn')['aria-label']).to eq("Resolved by #{user.name}")
        end

        page.within '.diff-content' do
          expect(page).to have_selector('.btn', text: 'Unresolve thread')
        end

        page.within '.line-resolve-all-container' do
          expect(page).to have_content('1/1 thread resolved')
          expect(page).to have_selector('.line-resolve-btn.is-active')
        end
      end

      it 'allows user to mark thread as resolved' do
        page.within '.diff-content' do
          click_button 'Resolve thread'
        end

        expect(page).to have_selector('.discussion-body', visible: false)

        page.within '.diff-content .note' do
          expect(page).to have_selector('.line-resolve-btn.is-active')
        end

        page.within '.line-resolve-all-container' do
          expect(page).to have_content('1/1 thread resolved')
          expect(page).to have_selector('.line-resolve-btn.is-active')
        end
      end

      it 'allows user to unresolve thread' do
        page.within '.diff-content' do
          click_button 'Resolve thread'
          click_button 'Unresolve thread'
        end

        page.within '.line-resolve-all-container' do
          expect(page).to have_content('0/1 thread resolved')
        end
      end

      describe 'resolved thread' do
        before do
          page.within '.diff-content' do
            click_button 'Resolve thread'
          end

          visit_merge_request
        end

        describe 'timeline view' do
          it 'hides when resolve thread is clicked' do
            expect(page).to have_selector('.discussion-header')
            expect(page).not_to have_selector('.discussion-body')
          end

          it 'shows resolved thread when toggled' do
            find(".timeline-content .discussion[data-discussion-id='#{note.discussion_id}'] .discussion-toggle-button").click

            expect(page.find(".line-holder-placeholder")).to be_visible
            expect(page.find(".timeline-content #note_#{note.id}")).to be_visible
          end

          it 'renders tables in lazy-loaded resolved diff dicussions' do
            find(".timeline-content .discussion[data-discussion-id='#{note.discussion_id}'] .discussion-toggle-button").click

            wait_for_requests

            expect(page.find(".timeline-content #note_#{note.id}")).not_to have_css(".line_holder")
            expect(page.find(".timeline-content #note_#{note.id}")).to have_css("tr", count: 2)
          end
        end

        describe 'side-by-side view' do
          before do
            page.within('.merge-request-tabs') { click_link 'Changes' }
            find('.js-show-diff-settings').click
            page.find('#parallel-diff-btn').click
          end

          it 'hides when resolve thread is clicked' do
            expect(page).not_to have_selector('.diffs .diff-file .notes_holder')
          end

          it 'shows resolved thread when toggled' do
            find('.diff-comment-avatar-holders').click

            expect(find('.diffs .diff-file .notes_holder')).to be_visible
          end
        end

        describe 'reply form' do
          before do
            click_button 'Toggle thread'

            page.within '.diff-content' do
              click_button 'Reply...'
            end
          end

          it 'allows user to comment' do
            page.within '.diff-content' do
              find('.js-note-text').set 'testing'

              click_button 'Comment'

              wait_for_requests
            end

            page.within '.line-resolve-all-container' do
              expect(page).to have_content('1/1 thread resolved')
            end
          end

          it 'allows user to unresolve from reply form without a comment' do
            page.within '.diff-content' do
              click_button 'Unresolve thread'

              wait_for_requests
            end

            page.within '.line-resolve-all-container' do
              expect(page).to have_content('0/1 thread resolved')
              expect(page).not_to have_selector('.line-resolve-btn.is-active')
            end
          end

          it 'allows user to comment & unresolve thread' do
            page.within '.diff-content' do
              find('.js-note-text').set 'testing'

              click_button 'Comment & unresolve thread'

              wait_for_requests
            end

            page.within '.line-resolve-all-container' do
              expect(page).to have_content('0/1 thread resolved')
            end
          end
        end
      end

      it 'allows user to resolve from reply form without a comment' do
        page.within '.diff-content' do
          click_button 'Reply...'

          click_button 'Resolve thread'
        end

        page.within '.line-resolve-all-container' do
          expect(page).to have_content('1/1 thread resolved')
          expect(page).to have_selector('.line-resolve-btn.is-active')
        end
      end

      it 'allows user to comment & resolve thread' do
        page.within '.diff-content' do
          click_button 'Reply...'

          find('.js-note-text').set 'testing'

          click_button 'Comment & resolve thread'
        end

        page.within '.line-resolve-all-container' do
          expect(page).to have_content('1/1 thread resolved')
          expect(page).to have_selector('.line-resolve-btn.is-active')
        end
      end

      it 'allows user to quickly scroll to next unresolved thread' do
        page.within '.line-resolve-all-container' do
          page.find('.discussion-next-btn').click
        end

        expect(page.evaluate_script("window.pageYOffset")).to be > 0
      end

      it 'hides jump to next button when all resolved' do
        page.within '.diff-content' do
          click_button 'Resolve thread'
        end

        expect(page).to have_selector('.discussion-next-btn', visible: false)
      end

      it 'updates updated text after resolving note' do
        page.within '.diff-content .note' do
          resolve_button = find('.line-resolve-btn')

          resolve_button.click
          wait_for_requests

          expect(resolve_button['aria-label']).to eq("Resolved by #{user.name}")
        end
      end

      it 'hides jump to next thread button' do
        page.within '.discussion-reply-holder' do
          expect(page).not_to have_selector('.discussion-next-btn')
        end
      end
    end

    context 'multiple notes' do
      before do
        create(:diff_note_on_merge_request, project: project, noteable: merge_request, in_reply_to: note)
        visit_merge_request
      end

      it 'does not mark thread as resolved when resolving single note' do
        page.within("#note_#{note.id}") do
          first('.line-resolve-btn').click

          wait_for_requests

          expect(first('.line-resolve-btn')['aria-label']).to eq("Resolved by #{user.name}")
        end

        expect(page).to have_content('Last updated')

        page.within '.line-resolve-all-container' do
          expect(page).to have_content('0/1 thread resolved')
        end
      end

      it 'resolves thread' do
        resolve_buttons = page.all('.note .line-resolve-btn', count: 2)
        resolve_buttons.each do |button|
          button.click
        end

        wait_for_requests

        resolve_buttons.each do |button|
          expect(button['aria-label']).to eq("Resolved by #{user.name}")
        end

        page.within '.line-resolve-all-container' do
          expect(page).to have_content('1/1 thread resolved')
        end
      end
    end

    context 'muliple threads' do
      before do
        create(:diff_note_on_merge_request, project: project, position: position, noteable: merge_request)
        visit_merge_request
      end

      it 'shows text with how many threads' do
        page.within '.line-resolve-all-container' do
          expect(page).to have_content('0/2 threads resolved')
        end
      end

      it 'allows user to mark a single note as resolved' do
        click_button('Resolve thread', match: :first)

        page.within '.line-resolve-all-container' do
          expect(page).to have_content('1/2 threads resolved')
        end
      end

      it 'allows user to mark all notes as resolved' do
        page.all('.note .line-resolve-btn', count: 2).each do |btn|
          btn.click
        end

        page.within '.line-resolve-all-container' do
          expect(page).to have_content('2/2 threads resolved')
          expect(page).to have_selector('.line-resolve-btn.is-active')
        end
      end

      it 'allows user to mark all threads as resolved' do
        page.all('.discussion-reply-holder', count: 2).each do |reply_holder|
          page.within reply_holder do
            click_button 'Resolve thread'
          end
        end

        page.within '.line-resolve-all-container' do
          expect(page).to have_content('2/2 threads resolved')
          expect(page).to have_selector('.line-resolve-btn.is-active')
        end
      end

      it 'allows user to quickly scroll to next unresolved thread' do
        page.within('.discussion-reply-holder', match: :first) do
          click_button 'Resolve thread'
        end

        page.within '.line-resolve-all-container' do
          page.find('.discussion-next-btn').click
        end

        expect(page.evaluate_script("window.pageYOffset")).to be > 0
      end

      it 'updates updated text after resolving note' do
        page.within('.diff-content .note', match: :first) do
          resolve_button = find('.line-resolve-btn')

          resolve_button.click
          wait_for_requests

          expect(resolve_button['aria-label']).to eq("Resolved by #{user.name}")
        end
      end

      it 'shows jump to next discussion button on all discussions' do
        wait_for_requests

        all_discussion_replies = page.all('.discussion-reply-holder')

        expect(all_discussion_replies.count).to eq(2)
        expect(all_discussion_replies.first.all('.discussion-next-btn').count).to eq(1)
        expect(all_discussion_replies.last.all('.discussion-next-btn').count).to eq(1)
      end

      it 'displays next thread even if hidden' do
        page.all('.note-discussion', count: 2).each do |discussion|
          page.within discussion do
            click_button 'Toggle thread'
          end
        end

        page.within('.issuable-discussion #notes') do
          expect(page).not_to have_selector('.btn', text: 'Resolve thread')
        end

        page.within '.line-resolve-all-container' do
          page.find('.discussion-next-btn').click
        end

        page.all('.note-discussion').first do
          expect(page.find('.discussion-with-resolve-btn')).to have_selector('.btn', text: 'Resolve thread')
        end

        page.all('.note-discussion').last do
          expect(page.find('.discussion-with-resolve-btn')).not.to have_selector('.btn', text: 'Resolve thread')
        end
      end
    end

    context 'changes tab' do
      it 'shows text with how many threads' do
        page.within '.line-resolve-all-container' do
          expect(page).to have_content('0/1 thread resolved')
        end
      end

      it 'allows user to mark a note as resolved' do
        page.within '.diff-content .note' do
          find('.line-resolve-btn').click

          expect(page).to have_selector('.line-resolve-btn.is-active')
        end

        page.within '.diff-content' do
          expect(page).to have_selector('.btn', text: 'Unresolve thread')
        end

        page.within '.line-resolve-all-container' do
          expect(page).to have_content('1/1 thread resolved')
          expect(page).to have_selector('.line-resolve-btn.is-active')
        end
      end

      it 'allows user to mark thread as resolved' do
        page.within '.diff-content' do
          click_button 'Resolve thread'
        end

        page.within '.diff-content .note' do
          expect(page).to have_selector('.line-resolve-btn.is-active')
        end

        page.within '.line-resolve-all-container' do
          expect(page).to have_content('1/1 thread resolved')
          expect(page).to have_selector('.line-resolve-btn.is-active')
        end
      end

      it 'allows user to unresolve thread' do
        page.within '.diff-content' do
          click_button 'Resolve thread'
          click_button 'Unresolve thread'
        end

        page.within '.line-resolve-all-container' do
          expect(page).to have_content('0/1 thread resolved')
        end
      end

      it 'allows user to comment & resolve thread' do
        page.within '.diff-content' do
          click_button 'Reply...'

          find('.js-note-text').set 'testing'

          click_button 'Comment & resolve thread'
        end

        page.within '.line-resolve-all-container' do
          expect(page).to have_content('1/1 thread resolved')
          expect(page).to have_selector('.line-resolve-btn.is-active')
        end
      end

      it 'allows user to comment & unresolve thread' do
        page.within '.diff-content' do
          click_button 'Resolve thread'

          click_button 'Reply...'

          find('.js-note-text').set 'testing'

          click_button 'Comment & unresolve thread'
        end

        page.within '.line-resolve-all-container' do
          expect(page).to have_content('0/1 thread resolved')
        end
      end
    end
  end

  context 'as a guest' do
    before do
      project.add_guest(guest)
      sign_in(guest)
    end

    context 'someone elses merge request' do
      before do
        visit_merge_request
      end

      it 'does not allow user to mark note as resolved' do
        page.within '.diff-content .note' do
          expect(page).not_to have_selector('.line-resolve-btn')
        end

        page.within '.line-resolve-all-container' do
          expect(page).to have_content('0/1 thread resolved')
        end
      end

      it 'does not allow user to mark thread as resolved' do
        page.within '.diff-content .note' do
          expect(page).not_to have_selector('.btn', text: 'Resolve thread')
        end
      end
    end

    context 'guest users merge request' do
      let(:user) { guest }

      before do
        visit_merge_request
      end

      it 'allows user to mark a note as resolved' do
        page.within '.diff-content .note' do
          find('.line-resolve-btn').click

          expect(page).to have_selector('.line-resolve-btn.is-active')
        end

        page.within '.diff-content' do
          expect(page).to have_selector('.btn', text: 'Unresolve thread')
        end

        page.within '.line-resolve-all-container' do
          expect(page).to have_content('1/1 thread resolved')
          expect(page).to have_selector('.line-resolve-btn.is-active')
        end
      end
    end
  end

  context 'unauthorized user' do
    context 'no resolved comments' do
      before do
        visit_merge_request
      end

      it 'does not allow user to mark note as resolved' do
        page.within '.diff-content .note' do
          expect(page).not_to have_selector('.line-resolve-btn')
        end

        page.within '.line-resolve-all-container' do
          expect(page).to have_content('0/1 thread resolved')
        end
      end
    end

    context 'resolved comment' do
      before do
        note.resolve!(user)
        visit_merge_request
      end

      it 'shows resolved icon' do
        expect(page).to have_content '1/1 thread resolved'

        click_button 'Toggle thread'
        expect(page).to have_selector('.line-resolve-btn.is-active')
      end

      it 'does not allow user to click resolve button' do
        expect(page).to have_selector('.line-resolve-btn.is-disabled')
        click_button 'Toggle thread'

        expect(page).to have_selector('.line-resolve-btn.is-disabled')
      end
    end
  end

  def visit_merge_request(mr = nil)
    mr ||= merge_request
    visit project_merge_request_path(mr.project, mr)
  end
end
