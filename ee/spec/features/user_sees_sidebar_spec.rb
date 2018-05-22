require 'spec_helper'

describe 'Projects > User sees sidebar' do
  let(:user) { create(:user) }
  let(:project) { create(:project, :private, public_builds: false, namespace: user.namespace) }

  context 'as guest' do
    let(:guest) { create(:user) }

    before do
      project.add_guest(guest)

      sign_in(guest)
    end

    it 'shows allowed tabs only' do
      visit project_path(project)

      within('.nav-sidebar') do
        expect(page).to have_content 'Overview'
      end
    end
  end
end
