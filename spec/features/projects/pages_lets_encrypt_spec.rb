# frozen_string_literal: true
require 'spec_helper'

describe "Pages with Let's Encrypt", :https_pages_enabled do
  include LetsEncryptHelpers

  let(:project) { create(:project) }
  let(:user) { create(:user) }
  let(:role) { :maintainer }
  let(:certificate_pem) { attributes_for(:pages_domain)[:certificate] }

  let(:certificate_key) { attributes_for(:pages_domain)[:key] }

  before do
    allow(Gitlab.config.pages).to receive(:enabled).and_return(true)
    stub_lets_encrypt_settings

    project.add_role(user, role)
    sign_in(user)
    project.namespace.update(owner: user)
    allow_any_instance_of(Project).to receive(:pages_deployed?) { true }
  end

  context 'when the auto SSL management is initially disabled' do
    let(:domain) do
      create(:pages_domain, auto_ssl_enabled: false, project: project)
    end

    it 'enables auto SSL and dynamically updates the form accordingly', :js do
      visit edit_project_pages_domain_path(project, domain)

      expect(domain.auto_ssl_enabled).to eq false

      expect(find("#pages_domain_auto_ssl_enabled", visible: false).value).to eq 'false'
      expect(page).to have_field 'Certificate (PEM)', type: 'textarea'
      expect(page).to have_field 'Key (PEM)', type: 'textarea'

      find('.js-auto-ssl-toggle-container .project-feature-toggle').click

      expect(find("#pages_domain_auto_ssl_enabled", visible: false).value).to eq 'true'
      expect(page).not_to have_field 'Certificate (PEM)', type: 'textarea'
      expect(page).not_to have_field 'Key (PEM)', type: 'textarea'

      click_on 'Save Changes'

      expect(domain.reload.auto_ssl_enabled).to eq true
    end
  end

  context 'when the auto SSL management is initially enabled' do
    let(:domain) do
      create(:pages_domain, :letsencrypt, auto_ssl_enabled: true, project: project)
    end

    it 'disables auto SSL and dynamically updates the form accordingly', :js do
      visit edit_project_pages_domain_path(project, domain)

      expect(find("#pages_domain_auto_ssl_enabled", visible: false).value).to eq 'true'
      expect(page).not_to have_field 'Certificate (PEM)', type: 'textarea'
      expect(page).not_to have_field 'Key (PEM)', type: 'textarea'

      find('.js-auto-ssl-toggle-container .project-feature-toggle').click

      expect(find("#pages_domain_auto_ssl_enabled", visible: false).value).to eq 'false'
      expect(page).to have_field 'Certificate (PEM)', type: 'textarea'
      expect(page).to have_field 'Key (PEM)', type: 'textarea'

      fill_in 'Certificate (PEM)', with: certificate_pem
      fill_in 'Key (PEM)', with: certificate_key

      click_on 'Save Changes'

      expect(domain.reload.auto_ssl_enabled).to eq false
    end
  end

  shared_examples 'user sees private keys only for user provided certificate' do
    before do
      visit edit_project_pages_domain_path(project, domain)
    end

    shared_examples 'user do not see private key' do
      it 'user do not see private key' do
        expect(find_field('Key (PEM)', visible: :all, disabled: :all).value).to be_blank
      end
    end

    context 'when auto_ssl is enabled for domain' do
      let(:domain) { create(:pages_domain, :letsencrypt, project: project, auto_ssl_enabled: true) }

      include_examples 'user do not see private key'
    end

    context 'when auto_ssl is disabled for domain' do
      let(:domain) { create(:pages_domain, :letsencrypt, project: project) }

      include_examples 'user do not see private key'
    end

    context 'when certificate is provided by user' do
      let(:domain) { create(:pages_domain, project: project) }

      it 'user sees private key' do
        expect(find_field('Key (PEM)').value).not_to be_blank
      end
    end
  end

  include_examples 'user sees private keys only for user provided certificate'

  context 'when letsencrypt is disabled' do
    let(:domain) do
      create(:pages_domain, auto_ssl_enabled: false, project: project)
    end

    before do
      stub_application_setting(lets_encrypt_terms_of_service_accepted: false)

      visit edit_project_pages_domain_path(project, domain)
    end

    it "does not render the Let's Encrypt field", :js do
      expect(page).not_to have_selector '.js-auto-ssl-toggle-container'
    end

    include_examples 'user sees private keys only for user provided certificate'
  end
end
