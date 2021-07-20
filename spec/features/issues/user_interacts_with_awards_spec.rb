# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User interacts with awards' do
  let(:user) { create(:user) }

  describe 'User interacts with awards in an issue', :js do
    let(:issue) { create(:issue, project: project)}
    let(:project) { create(:project) }

    before do
      project.add_maintainer(user)
      sign_in(user)

      visit(project_issue_path(project, issue))
    end

    it 'toggles the thumbsup award emoji', quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/27959' do
      page.within('.awards') do
        thumbsup = page.first('.award-control')
        thumbsup.click
        thumbsup.hover

        expect(page).to have_selector('.js-emoji-btn')
        expect(page).to have_css(".js-emoji-btn.active[data-original-title='You']")
        expect(page.find('.js-emoji-btn.active .js-counter')).to have_content('1')

        thumbsup = page.first('.award-control')
        thumbsup.click
        thumbsup.hover

        expect(page).to have_selector('.award-control.js-emoji-btn')
        expect(page.all('.award-control.js-emoji-btn').size).to eq(2)

        page.all('.award-control.js-emoji-btn').each do |element|
          expect(element['title']).to eq('')
        end

        expect(page.all('.award-control .js-counter')).to all(have_content('0'))

        thumbsup = page.first('.award-control')
        thumbsup.click
        thumbsup.hover

        expect(page).to have_selector('.js-emoji-btn')
        expect(page).to have_css(".js-emoji-btn.active[data-original-title='You']")
        expect(page.find('.js-emoji-btn.active .js-counter')).to have_content('1')
      end
    end

    it 'toggles a custom award emoji' do
      page.within('.awards') do
        page.find('.add-reaction-button').click
      end

      page.within('.emoji-picker') do
        emoji_button = page.first('gl-emoji[data-name="8ball"]')
        emoji_button.hover
        emoji_button.click
      end

      page.within('.awards') do
        expect(page).to have_selector('[data-testid="award-button"]')
        expect(page.find('[data-testid="award-button"].selected .js-counter')).to have_content('1')
        expect(page).to have_css('[data-testid="award-button"].selected[title="You reacted with :8ball:"]')

        expect do
          page.find('[data-testid="award-button"].selected').click
          wait_for_requests
        end.to change { page.all('[data-testid="award-button"]').size }.from(3).to(2)
      end
    end

    it 'shows the list of award emoji categories', quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/27991' do
      page.within('.awards') do
        page.find('.js-add-award').click
      end

      page.find('.emoji-menu.is-visible')

      expect(page).to have_selector('.js-emoji-menu-search')
      expect(page.evaluate_script("document.activeElement.classList.contains('js-emoji-menu-search')")).to eq(true)

      fill_in('emoji-menu-search', with: 'hand')

      page.within('.emoji-menu-content') do
        expect(page).to have_selector('[data-name="raised_hand"]')
      end
    end

    it 'adds an award emoji by a comment' do
      page.within('.js-main-target-form') do
        fill_in('note[note]', with: ':smile:')

        click_button('Comment')
      end

      expect(page).to have_emoji('smile')
    end

    context 'when a project is archived' do
      let(:project) { create(:project, :archived) }

      it 'hides the add award button' do
        page.within('.awards') do
          expect(page).not_to have_css('.js-add-award')
        end
      end
    end

    context 'User interacts with awards on a note' do
      let!(:note) { create(:note, noteable: issue, project: issue.project) }
      let!(:award_emoji) { create(:award_emoji, awardable: note, name: '100') }

      it 'shows the award on the note' do
        page.within('.note-awards') do
          expect(page).to have_emoji('100')
        end
      end

      it 'allows adding a vote to an award' do
        page.within('.note-awards') do
          find('gl-emoji[data-name="100"]').click
        end
        wait_for_requests

        expect(note.reload.award_emoji.size).to eq(2)
      end

      it 'allows adding a new emoji' do
        page.within('.note-actions') do
          find('.note-emoji-button').click
        end
        find('gl-emoji[data-name="8ball"]').click
        wait_for_requests

        page.within('.note-awards') do
          expect(page).to have_emoji('8ball')
        end
        expect(note.reload.award_emoji.size).to eq(2)
      end

      context 'when the project is archived' do
        let(:project) { create(:project, :archived) }

        it 'hides the buttons for adding new emoji' do
          page.within('.note-awards') do
            expect(page).not_to have_css('.award-menu-holder')
          end

          page.within('.note-actions') do
            expect(page).not_to have_css('.btn.js-add-award')
          end
        end

        it 'does not allow toggling existing emoji' do
          page.within('.note-awards') do
            find('gl-emoji[data-name="100"]').click
          end
          wait_for_requests

          expect(note.reload.award_emoji.size).to eq(1)
        end
      end
    end
  end

  describe 'User interacts with awards on an issue', :js do
    let(:project)   { create(:project, :public) }
    let(:issue)     { create(:issue, project: project) }

    describe 'logged in' do
      before do
        sign_in(user)
        visit project_issue_path(project, issue)
        wait_for_requests
      end

      context 'when the issue is locked' do
        before do
          create(:award_emoji, awardable: issue, name: '100')
          issue.update!(discussion_locked: true)

          visit project_issue_path(project, issue)
          wait_for_requests
        end

        it 'hides the add award button' do
          page.within('.awards') do
            expect(page).not_to have_css('.js-add-award')
          end
        end

        it 'does not allow toggling existing emoji' do
          page.within('.awards') do
            find('gl-emoji[data-name="100"]').click
          end
          wait_for_requests

          expect(issue.reload.award_emoji.size).to eq(1)
        end
      end

      it 'adds award to issue' do
        first('[data-testid="award-button"]').click

        expect(page).to have_selector('[data-testid="award-button"].selected')
        expect(first('[data-testid="award-button"]')).to have_content '1'

        visit project_issue_path(project, issue)

        expect(first('[data-testid="award-button"]')).to have_content '1'
      end

      it 'removes award from issue' do
        first('[data-testid="award-button"]').click
        find('[data-testid="award-button"].selected').click

        expect(first('[data-testid="award-button"]')).to have_content '0'

        visit project_issue_path(project, issue)

        expect(first('[data-testid="award-button"]')).to have_content '0'
      end
    end

    describe 'logged out' do
      before do
        visit project_issue_path(project, issue)
        wait_for_requests
      end

      it 'does not see award menu button' do
        expect(page).not_to have_selector('.js-award-holder')
      end
    end
  end

  describe 'Awards Emoji' do
    let!(:project)   { create(:project, :public) }
    let(:issue)      { create(:issue, assignees: [user], project: project) }

    context 'authorized user' do
      before do
        project.add_maintainer(user)
        sign_in(user)
      end

      describe 'visiting an issue with a legacy award emoji that is not valid anymore' do
        before do
          # The `heart_tip` emoji is not valid anymore so we need to skip validation
          issue.award_emoji.build(user: user, name: 'heart_tip').save!(validate: false)
          visit project_issue_path(project, issue)
          wait_for_requests
        end

        # Regression test: https://gitlab.com/gitlab-org/gitlab-foss/issues/29529
        it 'does not shows a 500 page', :js do
          expect(page).to have_text(issue.title)
        end
      end

      describe 'Click award emoji from issue#show' do
        let!(:note) { create(:note_on_issue, noteable: issue, project: issue.project, note: "Hello world") }

        before do
          visit project_issue_path(project, issue)
          wait_for_requests
        end

        context 'click the thumbsdown emoji' do
          it 'increments the thumbsdown emoji', :js do
            find('[data-name="thumbsdown"]').click
            wait_for_requests
            expect(thumbsdown_emoji).to have_text("1")
          end

          it 'decrements the thumbsup emoji', :js do
            expect(thumbsup_emoji).to have_text("0")
          end
        end

        it 'toggles the smiley emoji on a note', :js, quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/267525' do
          toggle_smiley_emoji(true)

          within('.note-body') do
            expect(find(emoji_counter)).to have_text("1")
          end

          toggle_smiley_emoji(false)

          within('.note-body') do
            expect(page).not_to have_selector(emoji_counter)
          end
        end

        context 'execute /award quick action' do
          xit 'toggles the emoji award on noteable', :js do
            execute_quick_action('/award :100:')

            expect(find(noteable_award_counter)).to have_text("1")

            execute_quick_action('/award :100:')

            expect(page).not_to have_selector(noteable_award_counter)
          end
        end
      end
    end

    context 'unauthorized user', :js do
      before do
        visit project_issue_path(project, issue)
      end

      it 'has disabled emoji button' do
        expect(first('[data-testid="award-button"]')[:class]).to have_text('disabled')
      end
    end

    def execute_quick_action(cmd)
      within('.js-main-target-form') do
        fill_in 'note[note]', with: cmd
        click_button 'Comment'
      end

      wait_for_requests
    end

    def thumbsup_emoji
      page.all(emoji_counter).first
    end

    def thumbsdown_emoji
      page.all(emoji_counter).last
    end

    def emoji_counter
      'span.js-counter'
    end

    def noteable_award_counter
      ".awards .is-active"
    end

    def toggle_smiley_emoji(status)
      within('.note') do
        find('.note-emoji-button').click
      end

      if !status
        first('[data-name="smiley"]').click
      else
        find('[data-name="smiley"]').click
      end

      wait_for_requests
    end
  end
end
