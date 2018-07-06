require 'rails_helper'

describe 'GFM autocomplete', :js do
  let(:user) { create(:user, name: '💃speciąl someone💃', username: 'someone.special') }
  let(:group) { create(:group) }
  let(:label) { create(:group_label, group: group, title: 'special+') }
  let(:epic) { create(:epic, group: group) }

  before do
    stub_licensed_features(epics: true)
    group.add_master(user)
    sign_in(user)
    visit group_epic_path(group, epic)

    wait_for_requests
  end

  context 'epics' do
    let!(:epic2) { create(:epic, group: group, title: 'make tea') }

    it 'shows epics' do
      note = find('#note-body')

      # It should show all the epics on "&".
      type(note, '&')
      expect_epics(shown: [epic, epic2])
    end
  end

  # This context has just one example in each contexts in order to improve spec performance.
  context 'labels' do
    let!(:backend)          { create(:group_label, group: group, title: 'backend') }
    let!(:bug)              { create(:group_label, group: group, title: 'bug') }
    let!(:feature_proposal) { create(:group_label, group: group, title: 'feature proposal') }

    context 'when no labels are assigned' do
      it 'shows labels' do
        note = find('#note-body')

        # It should show all the labels on "~".
        type(note, '~')
        expect_labels(shown: [backend, bug, feature_proposal])

        # It should show all the labels on "/label ~".
        type(note, '/label ~')
        expect_labels(shown: [backend, bug, feature_proposal])

        # It should show all the labels on "/relabel ~".
        type(note, '/relabel ~')
        expect_labels(shown: [backend, bug, feature_proposal])

        # It should show no labels on "/unlabel ~".
        type(note, '/unlabel ~')
        expect_labels(not_shown: [backend, bug, feature_proposal])
      end
    end

    context 'when some labels are assigned' do
      before do
        epic.labels << [backend]
      end

      skip 'shows labels' do
        note = find('#note-body')

        # It should show all the labels on "~".
        type(note, '~')
        expect_labels(shown: [backend, bug, feature_proposal])

        # It should show only unset labels on "/label ~".
        type(note, '/label ~')
        expect_labels(shown: [bug, feature_proposal], not_shown: [backend])

        # It should show all the labels on "/relabel ~".
        type(note, '/relabel ~')
        expect_labels(shown: [backend, bug, feature_proposal])

        # It should show only set labels on "/unlabel ~".
        type(note, '/unlabel ~')
        expect_labels(shown: [backend], not_shown: [bug, feature_proposal])
      end
    end

    context 'when all labels are assigned' do
      before do
        epic.labels << [backend, bug, feature_proposal]
      end

      skip 'shows labels' do
        note = find('#note-body')

        # It should show all the labels on "~".
        type(note, '~')
        expect_labels(shown: [backend, bug, feature_proposal])

        # It should show no labels on "/label ~".
        type(note, '/label ~')
        expect_labels(not_shown: [backend, bug, feature_proposal])

        # It should show all the labels on "/relabel ~".
        type(note, '/relabel ~')
        expect_labels(shown: [backend, bug, feature_proposal])

        # It should show all the labels on "/unlabel ~".
        type(note, '/unlabel ~')
        expect_labels(shown: [backend, bug, feature_proposal])
      end
    end
  end

  private

  def expect_to_wrap(should_wrap, item, note, value)
    expect(item).to have_content(value)
    expect(item).not_to have_content("\"#{value}\"")

    item.click

    if should_wrap
      expect(note.value).to include("\"#{value}\"")
    else
      expect(note.value).not_to include("\"#{value}\"")
    end
  end

  def expect_labels(shown: nil, not_shown: nil)
    page.within('.atwho-container') do
      if shown
        expect(page).to have_selector('.atwho-view li', count: shown.size)
        shown.each { |label| expect(page).to have_content(label.title) }
      end

      if not_shown
        expect(page).not_to have_selector('.atwho-view li') unless shown
        not_shown.each { |label| expect(page).not_to have_content(label.title) }
      end
    end
  end

  def expect_epics(shown: nil, not_shown: nil)
    page.within('.atwho-container') do
      if shown
        expect(page).to have_selector('.atwho-view li', count: shown.size)
        shown.each { |epic| expect(page).to have_content(epic.title) }
      end

      if not_shown
        expect(page).not_to have_selector('.atwho-view li') unless shown
        not_shown.each { |epic| expect(page).not_to have_content(epic.title) }
      end
    end
  end

  # `note` is a textarea where the given text should be typed.
  # We don't want to find it each time this function gets called.
  def type(note, text)
    page.within('.timeline-content-form') do
      note.set('')
      note.native.send_keys(text)
    end
  end
end
