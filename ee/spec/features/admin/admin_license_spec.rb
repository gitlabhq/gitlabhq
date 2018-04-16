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

    context 'with a trial license' do
      let!(:license) { create(:license, trial: true) }

      it 'shows expiration duration with license type' do
        visit admin_license_path

        page.within '.js-license-info-panel' do
          expect(page).to have_content('Expires: Free trial will expire in')
        end
      end
    end

    context 'with a regular license' do
      let!(:license) { create(:license) }

      it 'shows only expiration duration' do
        visit admin_license_path

        page.within '.js-license-info-panel' do
          expect(page).not_to have_content('Expires: Free trial will expire in')
        end
      end
    end

    context 'with an expired trial license' do
      let!(:license) { create(:license, trial: true, expired: true) }

      it 'does not mention blocking of changes' do
        visit admin_license_path

        page.within '.gitlab-ee-license-banner' do
          expect(page).to have_content('Your trial license expired on')
          expect(page).not_to have_content('Pushing code and creation of issues and merge requests has been disabled')
        end
      end
    end

    context 'when license key is provided in the query string' do
      let(:license) { build(:license, data: build(:gitlab_license, restrictions: { active_user_count: 2000 }).export) }

      before do
        License.destroy_all
      end

      it 'shows the modal to install the license' do
        visit admin_license_path(trial_key: license.data)

        page.within '#modal-upload-trial-license' do
          expect(page).to have_content('Your trial license was issued')
          expect(page).to have_button('Install license')
        end
      end

      it 'can install the license' do
        visit admin_license_path(trial_key: license.data)
        click_button 'Install license'

        expect(page).to have_content('The license was successfully uploaded and is now active')
      end
    end
  end
end
