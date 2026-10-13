# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Admin SSH certificate authorities', :js, feature_category: :source_code_management do
  include ListboxHelpers
  include Spec::Support::Helpers::ModalHelpers

  let_it_be(:admin) { create(:admin) }
  let!(:certificate) { create(:instance_ssh_certificate, title: 'Existing CA') }

  before do
    sign_in(admin)
    enable_admin_mode!(admin)
    visit admin_ssh_certificates_path
  end

  it 'lists certificate authorities with their fingerprint' do
    within_testid('ssh-certificates-list') do
      expect(page).to have_content(certificate.title)
      expect(page).to have_content(certificate.fingerprint.last(4))
    end
  end

  describe 'adding a certificate authority' do
    before do
      click_button 'Add certificate authority'
      fill_in 'certificate-authority-title', with: 'New CA'
    end

    it 'adds it to the list' do
      fill_in 'certificate-authority-key', with: build(:rsa_key_4096).key
      within_testid('certificate-authority-form') { click_button 'Add certificate authority' }

      within_testid('ssh-certificates-list') { expect(page).to have_content('New CA') }
    end

    it 'shows an inline error for an invalid key' do
      fill_in 'certificate-authority-key', with: 'invalid'

      within_testid('certificate-authority-form') do
        click_button 'Add certificate authority'

        expect(page).to have_content('Invalid key')
      end
    end
  end

  it 'deletes a certificate authority after confirming trust is revoked' do
    within('tr', text: certificate.title) { click_button 'More actions' }
    select_disclosure_dropdown_item 'Delete certificate authority'

    accept_gl_confirm('immediately revokes trust in this certificate authority',
      button_text: 'Delete certificate authority')

    expect(page).to have_content("This instance doesn't have any SSH certificate authorities.")
  end
end
