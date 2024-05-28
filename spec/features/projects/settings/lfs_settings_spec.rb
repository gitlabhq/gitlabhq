# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Projects > Settings > LFS settings', feature_category: :source_code_management do
  let(:project) { create(:project) }
  let(:user) { create(:user) }
  let(:role) { :maintainer }

  context 'LFS enabled setting' do
    before do
      allow(Gitlab.config.lfs).to receive(:enabled).and_return(true)

      sign_in(user)
      project.add_role(user, role)
    end

    context 'for maintainer' do
      let(:role) { :maintainer }

      it 'displays the correct elements', :js do
        visit edit_project_path(project)

        expect(page).to have_content('Git Large File Storage')
        expect(page).to have_selector('input[name="project[lfs_enabled]"] + button', visible: true)
      end
    end
  end
end
