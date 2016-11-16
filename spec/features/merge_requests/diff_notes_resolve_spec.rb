require 'spec_helper'

feature 'Diff notes resolve', feature: true, js: true do
  let(:user)          { create(:user) }
  let(:project)       { create(:project, :public) }
  let(:merge_request) { create(:merge_request_with_diffs, source_project: project, author: user, title: "Bug NS-04") }
  let!(:note)         { create(:diff_note_on_merge_request, project: project, noteable: merge_request) }
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

  context 'no discussions' do
    before do
      project.team << [user, :master]
      login_as user
      note.destroy
      visit_merge_request
    end

    it 'displays no discussion resolved data' do
      expect(page).not_to have_content('discussion resolved')
      expect(page).not_to have_selector('.discussion-next-btn')
    end
  end

  context 'as authorized user' do
    before do
      project.team << [user, :master]
      login_as user
      visit_merge_request
    end

    context 'single discussion' do
      it 'shows text with how many discussions' do
        page.within '.line-resolve-all-container' do
          expect(page).to have_content('0/1 discussion resolved')
        end
      end

      it 'allows user to mark a note as resolved' do
        page.within '.diff-content .note' do
          find('.line-resolve-btn').click

          expect(page).to have_selector('.line-resolve-btn.is-active')
          expect(find('.line-resolve-btn')['data-original-title']).to eq("Resolved by #{user.name}")
        end

        page.within '.diff-content' do
          expect(page).to have_selector('.btn', text: 'Unresolve discussion')
        end

        page.within '.line-resolve-all-container' do
          expect(page).to have_content('1/1 discussion resolved')
          expect(page).to have_selector('.line-resolve-btn.is-active')
        end
      end

      it 'allows user to mark discussion as resolved' do
        page.within '.diff-content' do
          click_button 'Resolve discussion'
        end

        page.within '.diff-content .note' do
          expect(page).to have_selector('.line-resolve-btn.is-active')
        end

        page.within '.line-resolve-all-container' do
          expect(page).to have_content('1/1 discussion resolved')
          expect(page).to have_selector('.line-resolve-btn.is-active')
        end
      end

      it 'allows user to unresolve discussion' do
        page.within '.diff-content' do
          click_button 'Resolve discussion'
          click_button 'Unresolve discussion'
        end

        page.within '.line-resolve-all-container' do
          expect(page).to have_content('0/1 discussion resolved')
        end
      end

      it 'hides resolved discussion' do
        page.within '.diff-content' do
          click_button 'Resolve discussion'
        end

        visit_merge_request

        expect(page).to have_selector('.discussion-body', visible: false)
      end

      it 'allows user to resolve from reply form without a comment' do
        page.within '.diff-content' do
          click_button 'Reply...'

          click_button 'Resolve discussion'
        end

        page.within '.line-resolve-all-container' do
          expect(page).to have_content('1/1 discussion resolved')
          expect(page).to have_selector('.line-resolve-btn.is-active')
        end
      end

      it 'allows user to unresolve from reply form without a comment' do
        page.within '.diff-content' do
          click_button 'Resolve discussion'
          sleep 1

          click_button 'Reply...'

          click_button 'Unresolve discussion'
        end

        page.within '.line-resolve-all-container' do
          expect(page).to have_content('0/1 discussion resolved')
          expect(page).not_to have_selector('.line-resolve-btn.is-active')
        end
      end

      it 'allows user to comment & resolve discussion' do
        page.within '.diff-content' do
          click_button 'Reply...'

          find('.js-note-text').set 'testing'

          click_button 'Comment & resolve discussion'
        end

        page.within '.line-resolve-all-container' do
          expect(page).to have_content('1/1 discussion resolved')
          expect(page).to have_selector('.line-resolve-btn.is-active')
        end
      end

      it 'allows user to comment & unresolve discussion' do
        page.within '.diff-content' do
          click_button 'Resolve discussion'

          click_button 'Reply...'

          find('.js-note-text').set 'testing'

          click_button 'Comment & unresolve discussion'
        end

        page.within '.line-resolve-all-container' do
          expect(page).to have_content('0/1 discussion resolved')
        end
      end

      it 'allows user to quickly scroll to next unresolved discussion' do
        page.within '.line-resolve-all-container' do
          page.find('.discussion-next-btn').click
        end

        expect(page.evaluate_script("$('body').scrollTop()")).to be > 0
      end

      it 'hides jump to next button when all resolved' do
        page.within '.diff-content' do
          click_button 'Resolve discussion'
        end

        expect(page).to have_selector('.discussion-next-btn', visible: false)
      end

      it 'updates updated text after resolving note' do
        page.within '.diff-content .note' do
          find('.line-resolve-btn').click
        end

        expect(page).to have_content("Resolved by #{user.name}")
      end

      it 'hides jump to next discussion button' do
        page.within '.discussion-reply-holder' do
          expect(page).not_to have_selector('.discussion-next-btn')
        end
      end
    end

    context 'multiple notes' do
      before do
        create(:diff_note_on_merge_request, project: project, noteable: merge_request)
        visit_merge_request
      end

      it 'does not mark discussion as resolved when resolving single note' do
        page.first '.diff-content .note' do
          first('.line-resolve-btn').click
          expect(first('.line-resolve-btn')['data-original-title']).to eq("Resolved by #{user.name}")
        end

        expect(page).to have_content('Last updated')

        page.within '.line-resolve-all-container' do
          expect(page).to have_content('0/1 discussion resolved')
        end
      end

      it 'resolves discussion' do
        page.all('.note').each do |note|
          note.all('.line-resolve-btn').each do |button|
            button.click
          end
        end

        expect(page).to have_content('Resolved by')

        page.within '.line-resolve-all-container' do
          expect(page).to have_content('1/1 discussion resolved')
        end
      end
    end

    context 'muliple discussions' do
      before do
        create(:diff_note_on_merge_request, project: project, position: position, noteable: merge_request)
        visit_merge_request
      end

      it 'shows text with how many discussions' do
        page.within '.line-resolve-all-container' do
          expect(page).to have_content('0/2 discussions resolved')
        end
      end

      it 'allows user to mark a single note as resolved' do
        click_button('Resolve discussion', match: :first)

        page.within '.line-resolve-all-container' do
          expect(page).to have_content('1/2 discussions resolved')
        end
      end

      it 'allows user to mark all notes as resolved' do
        page.all('.line-resolve-btn').each do |btn|
          btn.click
        end

        page.within '.line-resolve-all-container' do
          expect(page).to have_content('2/2 discussions resolved')
          expect(page).to have_selector('.line-resolve-btn.is-active')
        end
      end

      it 'allows user user to mark all discussions as resolved' do
        page.all('.discussion-reply-holder').each do |reply_holder|
          page.within reply_holder do
            click_button 'Resolve discussion'
          end
        end

        page.within '.line-resolve-all-container' do
          expect(page).to have_content('2/2 discussions resolved')
          expect(page).to have_selector('.line-resolve-btn.is-active')
        end
      end

      it 'allows user to quickly scroll to next unresolved discussion' do
        page.within first('.discussion-reply-holder') do
          click_button 'Resolve discussion'
        end

        page.within '.line-resolve-all-container' do
          page.find('.discussion-next-btn').click
        end

        expect(page.evaluate_script("$('body').scrollTop()")).to be > 0
      end

      it 'updates updated text after resolving note' do
        page.within first('.diff-content .note') do
          find('.line-resolve-btn').click
        end

        expect(page).to have_content("Resolved by #{user.name}")
      end

      it 'shows jump to next discussion button' do
        page.all('.discussion-reply-holder').each do |holder|
          expect(holder).to have_selector('.discussion-next-btn')
        end
      end

      it 'displays next discussion even if hidden' do
        page.all('.note-discussion').each do |discussion|
          page.within discussion do
            click_link 'Toggle discussion'
          end
        end

        page.within('.issuable-discussion #notes') do
          expect(page).not_to have_selector('.btn', text: 'Resolve discussion')
        end

        page.within '.line-resolve-all-container' do
          page.find('.discussion-next-btn').click
        end

        expect(find('.discussion-with-resolve-btn')).to have_selector('.btn', text: 'Resolve discussion')
      end
    end

    context 'changes tab' do
      it 'shows text with how many discussions' do
        page.within '.line-resolve-all-container' do
          expect(page).to have_content('0/1 discussion resolved')
        end
      end

      it 'allows user to mark a note as resolved' do
        page.within '.diff-content .note' do
          find('.line-resolve-btn').click

          expect(page).to have_selector('.line-resolve-btn.is-active')
        end

        page.within '.diff-content' do
          expect(page).to have_selector('.btn', text: 'Unresolve discussion')
        end

        page.within '.line-resolve-all-container' do
          expect(page).to have_content('1/1 discussion resolved')
          expect(page).to have_selector('.line-resolve-btn.is-active')
        end
      end

      it 'allows user to mark discussion as resolved' do
        page.within '.diff-content' do
          click_button 'Resolve discussion'
        end

        page.within '.diff-content .note' do
          expect(page).to have_selector('.line-resolve-btn.is-active')
        end

        page.within '.line-resolve-all-container' do
          expect(page).to have_content('1/1 discussion resolved')
          expect(page).to have_selector('.line-resolve-btn.is-active')
        end
      end

      it 'allows user to unresolve discussion' do
        page.within '.diff-content' do
          click_button 'Resolve discussion'
          click_button 'Unresolve discussion'
        end

        page.within '.line-resolve-all-container' do
          expect(page).to have_content('0/1 discussion resolved')
        end
      end

      it 'allows user to comment & resolve discussion' do
        page.within '.diff-content' do
          click_button 'Reply...'

          find('.js-note-text').set 'testing'

          click_button 'Comment & resolve discussion'
        end

        page.within '.line-resolve-all-container' do
          expect(page).to have_content('1/1 discussion resolved')
          expect(page).to have_selector('.line-resolve-btn.is-active')
        end
      end

      it 'allows user to comment & unresolve discussion' do
        page.within '.diff-content' do
          click_button 'Resolve discussion'

          click_button 'Reply...'

          find('.js-note-text').set 'testing'

          click_button 'Comment & unresolve discussion'
        end

        page.within '.line-resolve-all-container' do
          expect(page).to have_content('0/1 discussion resolved')
        end
      end
    end
  end

  context 'as a guest' do
    let(:guest) { create(:user) }

    before do
      project.team << [guest, :guest]
      login_as guest
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
          expect(page).to have_content('0/1 discussion resolved')
        end
      end

      it 'does not allow user to mark discussion as resolved' do
        page.within '.diff-content .note' do
          expect(page).not_to have_selector('.btn', text: 'Resolve discussion')
        end
      end
    end

    context 'guest users merge request' do
      before do
        mr = create(:merge_request_with_diffs, source_project: project, source_branch: 'markdown', author: guest, title: "Bug")
        create(:diff_note_on_merge_request, project: project, noteable: mr)
        visit_merge_request(mr)
      end

      it 'allows user to mark a note as resolved' do
        page.within '.diff-content .note' do
          find('.line-resolve-btn').click

          expect(page).to have_selector('.line-resolve-btn.is-active')
        end

        page.within '.diff-content' do
          expect(page).to have_selector('.btn', text: 'Unresolve discussion')
        end

        page.within '.line-resolve-all-container' do
          expect(page).to have_content('1/1 discussion resolved')
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
          expect(page).to have_content('0/1 discussion resolved')
        end
      end
    end

    context 'resolved comment' do
      before do
        note.resolve!(user)
        visit_merge_request
      end

      it 'shows resolved icon' do
        expect(page).to have_content '1/1 discussion resolved'

        click_link 'Toggle discussion'
        expect(page).to have_selector('.line-resolve-btn.is-active')
      end

      it 'does not allow user to click resolve button' do
        expect(page).to have_selector('.line-resolve-btn.is-disabled')
        click_link 'Toggle discussion'

        expect(page).to have_selector('.line-resolve-btn.is-disabled')
      end
    end
  end

  def visit_merge_request(mr = nil)
    mr = mr || merge_request
    visit namespace_project_merge_request_path(mr.project.namespace, mr.project, mr)
  end
end
