require 'spec_helper'

describe 'User interacts with awards in an issue', :js do
  let(:issue) { create(:issue, project: project)}
  let(:project) { create(:project) }
  let(:user) { create(:user) }

  before do
    project.add_master(user)
    sign_in(user)

    visit(project_issue_path(project, issue))
  end

  it 'toggles the thumbsup award emoji' do
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

      page.all('.award-control .js-counter').each do |element|
        expect(element).to have_content('0')
      end

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
      page.find('.js-add-award').click
    end

    page.find('.emoji-menu.is-visible')

    expect(page).to have_selector('.js-emoji-menu-search')
    expect(page.evaluate_script("document.activeElement.classList.contains('js-emoji-menu-search')")).to eq(true)

    page.within('.emoji-menu-content') do
      emoji_button = page.first('.js-emoji-btn')
      emoji_button.hover
      emoji_button.click
    end

    page.within('.awards') do
      expect(page).to have_selector('.js-emoji-btn')
      expect(page.find('.js-emoji-btn.active .js-counter')).to have_content('1')
      expect(page).to have_css(".js-emoji-btn.active[data-original-title='You']")

      expect do
        page.find('.js-emoji-btn.active').click
        wait_for_requests
      end.to change { page.all('.award-control.js-emoji-btn').size }.from(3).to(2)
    end
  end

  it 'shows the list of award emoji categories' do
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

  context 'awards on a note' do
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
        find('a.js-add-award').click
      end
      page.within('.emoji-menu-content') do
        find('gl-emoji[data-name="8ball"]').click
      end
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
          expect(page).not_to have_css('a.js-add-award')
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
