require 'spec_helper'

feature "Creating trial license", feature: true do
  before do
    gitlab_sign_in :admin
  end

  describe 'GET /admin/trials/new' do
    context 'without a previous trial license' do
      let!(:license_data) { create(:license, trial: true).data }
      let(:body) do
        { 'license_key' => license_data }
      end

      before { License.destroy_all }

      it 'allows the creation of the trial license' do
        stub_request(:post, "#{Gitlab::SUBSCRIPTIONS_URL}/trials")
          .to_return(body: JSON(body), status: 200, headers: { 'Content-Type' => 'application/json' })

        visit new_admin_trials_path

        fill_in :first_name, with: 'John'
        fill_in :last_name, with: 'Doe'
        fill_in :work_email, with: 'john@local.dev'
        fill_in :company_name, with: 'GitLab'
        fill_in :phone_number, with: '111-111111'
        fill_in :number_of_developers, with: 50
        fill_in :number_of_users, with: 100
        select('United States', from: 'Country')

        click_button 'Start your free trial'

        expect(page).to have_content('Your trial license was successfully activated')
      end
    end

    context 'with an active license' do
      it 'does not render the form and shows an error' do
        create(:license)

        visit new_admin_trials_path

        expect(page).to have_content('You already have an active license key installed on this server')
      end
    end

    context 'with a previous expired trial license' do
      it 'does not render the form and shows an error' do
        create(:license, trial: true, expired: true)

        visit new_admin_trials_path

        expect(page).to have_content('You have already used a free trial')
      end
    end

  end
end
