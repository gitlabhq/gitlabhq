require 'spec_helper'

feature 'Group activity page' do
  let(:user) { create(:group_member, :developer, user: create(:user), group: group ).user }
  let(:group) { create(:group) }
  let(:path) { activity_group_path(group) }

  context 'when signed in' do
    before do
      sign_in(user)
    end

    describe 'RSS' do
      before do
        visit path
      end

      it_behaves_like "it has an RSS button with current_user's RSS token"
      it_behaves_like "an autodiscoverable RSS feed with current_user's RSS token"
    end

    context 'when project in the group', :js do
      let(:project) { create(:project, :public, namespace: group) }

      before do
        project.add_master(user)

        visit path
      end

      it 'renders user joined to project event' do
        expect(page).to have_content 'joined project'
      end
    end
  end

  context 'when signed out' do
    before do
      visit path
    end

    it_behaves_like "it has an RSS button without an RSS token"
    it_behaves_like "an autodiscoverable RSS feed without an RSS token"
  end
end
