require 'spec_helper'

feature "License Admin" do
  before do
    sign_in(create(:admin))
  end

  describe '#show' do
    it 'shows a valid license' do
      visit admin_license_path

      expect(page).to have_content('Your license is valid')
      page.within '.license-panel' do
        expect(page).to have_content('Unlimited')
      end
    end

    describe 'limited users' do
      let!(:license) { create(:license, data: build(:gitlab_license, restrictions: { active_user_count: 2000 }).export) }

      it 'shows panel counts' do
        visit admin_license_path

        page.within '.license-panel' do
          expect(page).to have_content('2,000')
        end
      end
    end
  end
end
