# frozen_string_literal: true
require 'spec_helper'

RSpec.describe 'User adds pages domain', :js do
  include LetsEncryptHelpers

  let_it_be(:project) { create(:project, pages_https_only: false) }

  let(:user) { create(:user) }

  before do
    allow(Gitlab.config.pages).to receive(:enabled).and_return(true)

    project.add_maintainer(user)

    sign_in(user)
  end

  context 'when pages are exposed on external HTTP address', :http_pages_enabled do
    let(:project) { create(:project, pages_https_only: false) }

    shared_examples 'adds new domain' do
      it 'adds new domain' do
        visit new_project_pages_domain_path(project)

        fill_in 'Domain', with: 'my.test.domain.com'
        click_button 'Create New Domain'

        expect(page).to have_content('my.test.domain.com')
      end
    end

    it 'allows to add new domain' do
      visit project_pages_path(project)

      expect(page).to have_content('New Domain')
    end

    it_behaves_like 'adds new domain'

    context 'when project in group namespace' do
      it_behaves_like 'adds new domain' do
        let(:group) { create :group }
        let(:project) { create(:project, namespace: group, pages_https_only: false) }
      end
    end

    context 'when pages domain is added' do
      before do
        create(:pages_domain, project: project, domain: 'my.test.domain.com')

        visit new_project_pages_domain_path(project)
      end

      it 'renders certificates is disabled' do
        expect(page).to have_content('Support for custom certificates is disabled')
      end

      it 'does not adds new domain and renders error message' do
        fill_in 'Domain', with: 'my.test.domain.com'
        click_button 'Create New Domain'

        expect(page).to have_content('Domain has already been taken')
      end
    end
  end

  context 'when pages are exposed on external HTTPS address', :https_pages_enabled, :js do
    let(:certificate_pem) do
      attributes_for(:pages_domain)[:certificate]
    end

    let(:certificate_key) do
      attributes_for(:pages_domain)[:key]
    end

    it 'adds new domain with certificate' do
      visit new_project_pages_domain_path(project)

      fill_in 'Domain', with: 'my.test.domain.com'

      fill_in 'Certificate (PEM)', with: certificate_pem
      fill_in 'Key (PEM)', with: certificate_key
      click_button 'Create New Domain'

      expect(page).to have_content('my.test.domain.com')
    end

    it "adds new domain with certificate if Let's Encrypt is enabled" do
      stub_lets_encrypt_settings

      visit new_project_pages_domain_path(project)

      fill_in 'Domain', with: 'my.test.domain.com'

      find('.js-auto-ssl-toggle-container .project-feature-toggle').click

      fill_in 'Certificate (PEM)', with: certificate_pem
      fill_in 'Key (PEM)', with: certificate_key
      click_button 'Create New Domain'

      expect(page).to have_content('my.test.domain.com')
    end

    it 'shows validation error if domain is duplicated' do
      project.pages_domains.create!(domain: 'my.test.domain.com')

      visit new_project_pages_domain_path(project)

      fill_in 'Domain', with: 'my.test.domain.com'
      click_button 'Create New Domain'

      expect(page).to have_content('Domain has already been taken')
    end

    describe 'with dns verification enabled' do
      before do
        stub_application_setting(pages_domain_verification_enabled: true)
      end

      it 'shows the DNS verification record' do
        domain = create(:pages_domain, project: project)

        visit project_pages_path(project)

        within('#content-body') { click_link 'Edit' }
        expect(page).to have_field :domain_verification, with: "#{domain.verification_domain} TXT #{domain.keyed_verification_code}"
      end
    end

    describe 'updating the certificate for an existing domain' do
      let!(:domain) do
        create(:pages_domain, project: project, auto_ssl_enabled: false)
      end

      it 'allows the certificate to be updated' do
        visit project_pages_path(project)

        within('#content-body') { click_link 'Edit' }
        click_button 'Save Changes'

        expect(page).to have_content('Domain was updated')
      end

      context 'when the certificate is invalid' do
        let!(:domain) do
          create(:pages_domain, :without_certificate, :without_key, project: project)
        end

        it 'tells the user what the problem is' do
          visit project_pages_path(project)

          within('#content-body') { click_link 'Edit' }

          fill_in 'Certificate (PEM)', with: 'invalid data'
          click_button 'Save Changes'

          expect(page).to have_content('Certificate must be a valid PEM certificate')
          expect(page).to have_content('Certificate misses intermediates')
          expect(page).to have_content("Key doesn't match the certificate")
        end
      end

      it 'allows the certificate to be removed', :js do
        visit project_pages_path(project)

        within('#content-body') { click_link 'Edit' }

        accept_confirm { click_link 'Remove' }

        expect(page).to have_field('Certificate (PEM)', with: '')
        expect(page).to have_field('Key (PEM)', with: '')
        domain.reload
        expect(domain.certificate).to be_nil
        expect(domain.key).to be_nil
      end

      it 'shows the DNS CNAME record' do
        visit project_pages_path(project)

        within('#content-body') { click_link 'Edit' }
        expect(page).to have_field :domain_dns, with: "#{domain.domain} CNAME #{domain.project.pages_subdomain}.#{Settings.pages.host}."
      end
    end
  end
end
