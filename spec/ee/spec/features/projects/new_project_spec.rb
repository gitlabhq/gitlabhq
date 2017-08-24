require 'spec_helper'

feature 'New project' do
  let(:user) { create(:admin) }

  before do
    sign_in(user)
  end

  context 'repository mirrors' do
    context 'when licensed' do
      before do
        stub_licensed_features(repository_mirrors: true)
      end

      it 'shows mirror repository checkbox enabled', :js do
        visit new_project_path
        first('.import_git').click

        expect(page).to have_unchecked_field('Mirror repository', disabled: false)
      end
    end

    context 'when unlicensed' do
      before do
        stub_licensed_features(repository_mirrors: false)
      end

      it 'does not show mirror repository option' do
        visit new_project_path
        first('.import_git').click

        expect(page).not_to have_content('Mirror repository')
      end
    end
  end
end
