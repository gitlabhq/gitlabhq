require 'spec_helper'

feature "License Admin", feature: true do
  before do
    login_as :admin
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
      it 'shows panel counts' do
        restrictions = { active_user_count: 2000 }
        allow_any_instance_of(Gitlab::License).to receive(:restrictions).and_return(restrictions)
        visit admin_license_path

        page.within '.license-panel' do
          expect(page).to have_content('2,000')
        end
      end
    end
  end
end
