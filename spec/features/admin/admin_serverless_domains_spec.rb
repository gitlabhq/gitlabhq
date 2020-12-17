# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Admin Serverless Domains', :js do
  let(:sample_domain) { build(:pages_domain) }

  before do
    allow(Gitlab.config.pages).to receive(:enabled).and_return(true)
    admin = create(:admin)
    sign_in(admin)
    gitlab_enable_admin_mode_sign_in(admin)
  end

  it 'add domain with certificate' do
    visit admin_serverless_domains_path

    fill_in 'pages_domain[domain]', with: 'foo.com'
    fill_in 'pages_domain[user_provided_certificate]', with: sample_domain.certificate
    fill_in 'pages_domain[user_provided_key]', with: sample_domain.key
    click_button 'Add domain'

    expect(current_path).to eq admin_serverless_domains_path

    expect(page).to have_field('pages_domain[domain]', with: 'foo.com')
    expect(page).to have_field('serverless_domain_dns', with: /^\*\.foo\.com CNAME /)
    expect(page).to have_field('serverless_domain_verification', with: /^_gitlab-pages-verification-code.foo.com TXT /)
    expect(page).not_to have_field('pages_domain[user_provided_certificate]')
    expect(page).not_to have_field('pages_domain[user_provided_key]')

    expect(page).to have_content 'Unverified'
    expect(page).to have_content '/CN=test-certificate'
  end

  it 'update domain certificate' do
    visit admin_serverless_domains_path

    fill_in 'pages_domain[domain]', with: 'foo.com'
    fill_in 'pages_domain[user_provided_certificate]', with: sample_domain.certificate
    fill_in 'pages_domain[user_provided_key]', with: sample_domain.key
    click_button 'Add domain'

    expect(current_path).to eq admin_serverless_domains_path

    expect(page).not_to have_field('pages_domain[user_provided_certificate]')
    expect(page).not_to have_field('pages_domain[user_provided_key]')

    click_button 'Replace'

    expect(page).to have_field('pages_domain[user_provided_certificate]')
    expect(page).to have_field('pages_domain[user_provided_key]')

    fill_in 'pages_domain[user_provided_certificate]', with: sample_domain.certificate
    fill_in 'pages_domain[user_provided_key]', with: sample_domain.key

    click_button 'Save changes'

    expect(page).to have_content 'Domain was successfully updated'
    expect(page).to have_content '/CN=test-certificate'
  end

  context 'when domain exists' do
    let!(:domain) { create(:pages_domain, :instance_serverless) }

    it 'displays a modal when attempting to delete a domain' do
      visit admin_serverless_domains_path

      click_button 'Delete domain'

      page.within '#modal-delete-domain' do
        expect(page).to have_content "You are about to delete #{domain.domain} from your instance."
        expect(page).to have_link('Delete domain')
      end
    end

    it 'displays a modal with disabled button if unable to delete a domain' do
      create(:serverless_domain_cluster, pages_domain: domain)

      visit admin_serverless_domains_path

      click_button 'Delete domain'

      page.within '#modal-delete-domain' do
        expect(page).to have_content "You must disassociate #{domain.domain} from all clusters it is attached to before deletion."
        expect(page).to have_link('Delete domain')
      end
    end
  end
end
