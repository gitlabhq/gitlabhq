require 'spec_helper'

feature 'Group show page' do
  let(:group) { create(:group) }
  let(:path) { group_path(group) }

  context 'when signed in' do
    let(:user) do
      create(:group_member, :developer, user: create(:user), group: group ).user
    end

    before do
      sign_in(user)
      visit path
    end

    it_behaves_like "an autodiscoverable RSS feed with current_user's RSS token"

    context 'when group does not exist' do
      let(:path) { group_path('not-exist') }

      it { expect(status_code).to eq(404) }
    end
  end

  context 'when signed out' do
    describe 'RSS' do
      before do
        visit path
      end

      it_behaves_like "an autodiscoverable RSS feed without an RSS token"
<<<<<<< HEAD
    end

    context 'when group has a public project', :js do
      let!(:project) { create(:project, :public, namespace: group) }

      it 'renders public project' do
        visit path

        expect(page).to have_link group.name
        expect(page).to have_link project.name
=======
    end

    context 'when group has a public project', :js do
      let!(:project) { create(:project, :public, namespace: group) }

      it 'renders public project' do
        visit path

        expect(page).to have_link group.name
        expect(page).to have_link project.name
      end
    end

    context 'when group has a private project', :js do
      let!(:project) { create(:project, :private, namespace: group) }

      it 'does not render private project' do
        visit path

        expect(page).to have_link group.name
        expect(page).not_to have_link project.name
>>>>>>> upstream/master
      end
    end
  end

  context 'subgroup support' do
    let(:user) { create(:user) }

    before do
      group.add_owner(user)
      sign_in(user)
    end

    context 'when subgroups are supported', :js, :nested_groups do
      before do
        allow(Group).to receive(:supports_nested_groups?) { true }
        visit path
      end

      it 'allows creating subgroups' do
        expect(page).to have_css("li[data-text='New subgroup']", visible: false)
      end
    end

    context 'when subgroups are not supported' do
      before do
        allow(Group).to receive(:supports_nested_groups?) { false }
        visit path
      end

      it 'allows creating subgroups' do
        expect(page).not_to have_selector("li[data-text='New subgroup']", visible: false)
      end
    end
  end

  context 'group has a project with emoji in description', :js do
    let(:user) { create(:user) }
    let!(:project) { create(:project, description: ':smile:', namespace: group) }

    before do
      group.add_owner(user)
      sign_in(user)
      visit path
    end

    it 'shows the project info' do
      expect(page).to have_content(project.title)
      expect(page).to have_selector('gl-emoji[data-name="smile"]')
    end
  end
end
