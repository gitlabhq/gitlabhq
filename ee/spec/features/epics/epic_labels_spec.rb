require 'spec_helper'

describe 'Assign labels to an epic', :js do
  let(:user) { create(:user) }
  let(:group) { create(:group, :public) }
  let(:label) { create(:group_label, group: group, title: 'bug') }
  let(:epic) { create(:epic, group: group) }

  before do
    group.add_developer(user)
    stub_licensed_features(epics: true)
    sign_in(user)

    visit group_epic_path(group, epic)
  end

  context 'when label is referenced' do
    before do
      fill_in 'note[note]', with: "refer ~#{label.name}"
      click_button 'Comment'

      wait_for_requests
    end

    it 'creates new system note with label pointing to epics index page' do
      page.within('div#notes li.note div.note-text') do
        expect(page).to have_content("refer #{label.name}")
        expect(page.find('a')).to have_content(label.name)
        expect(page).to have_link(label.name, href: group_epics_path(group, label_name: label.name))
      end
    end
  end
end
