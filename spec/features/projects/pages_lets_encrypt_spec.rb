# frozen_string_literal: true
require 'spec_helper'

describe "Pages with Let's Encrypt", :https_pages_enabled do
  let(:project) { create(:project) }
  let(:user) { create(:user) }
  let(:role) { :maintainer }
  let(:certificate_pem) do
    <<~PEM
    -----BEGIN CERTIFICATE-----
    MIICGzCCAYSgAwIBAgIBATANBgkqhkiG9w0BAQUFADAbMRkwFwYDVQQDExB0ZXN0
    LWNlcnRpZmljYXRlMB4XDTE2MDIxMjE0MzIwMFoXDTIwMDQxMjE0MzIwMFowGzEZ
    MBcGA1UEAxMQdGVzdC1jZXJ0aWZpY2F0ZTCBnzANBgkqhkiG9w0BAQEFAAOBjQAw
    gYkCgYEApL4J9L0ZxFJ1hI1LPIflAlAGvm6ZEvoT4qKU5Xf2JgU7/2geNR1qlNFa
    SvCc08Knupp5yTgmvyK/Xi09U0N82vvp4Zvr/diSc4A/RA6Mta6egLySNT438kdT
    nY2tR5feoTLwQpX0t4IMlwGQGT5h6Of2fKmDxzuwuyffcIHqLdsCAwEAAaNvMG0w
    DAYDVR0TAQH/BAIwADAdBgNVHQ4EFgQUxl9WSxBprB0z0ibJs3rXEk0+95AwCwYD
    VR0PBAQDAgXgMBEGCWCGSAGG+EIBAQQEAwIGQDAeBglghkgBhvhCAQ0EERYPeGNh
    IGNlcnRpZmljYXRlMA0GCSqGSIb3DQEBBQUAA4GBAGC4T8SlFHK0yPSa+idGLQFQ
    joZp2JHYvNlTPkRJ/J4TcXxBTJmArcQgTIuNoBtC+0A/SwdK4MfTCUY4vNWNdese
    5A4K65Nb7Oh1AdQieTBHNXXCdyFsva9/ScfQGEl7p55a52jOPs0StPd7g64uvjlg
    YHi2yesCrOvVXt+lgPTd
    -----END CERTIFICATE-----
    PEM
  end

  let(:certificate_key) do
    <<~KEY
    -----BEGIN PRIVATE KEY-----
    MIICdgIBADANBgkqhkiG9w0BAQEFAASCAmAwggJcAgEAAoGBAKS+CfS9GcRSdYSN
    SzyH5QJQBr5umRL6E+KilOV39iYFO/9oHjUdapTRWkrwnNPCp7qaeck4Jr8iv14t
    PVNDfNr76eGb6/3YknOAP0QOjLWunoC8kjU+N/JHU52NrUeX3qEy8EKV9LeCDJcB
    kBk+Yejn9nypg8c7sLsn33CB6i3bAgMBAAECgYA2D26w80T7WZvazYr86BNMePpd
    j2mIAqx32KZHzt/lhh40J/SRtX9+Kl0Y7nBoRR5Ja9u/HkAIxNxLiUjwg9r6cpg/
    uITEF5nMt7lAk391BuI+7VOZZGbJDsq2ulPd6lO+C8Kq/PI/e4kXcIjeH6KwQsuR
    5vrXfBZ3sQfflaiN4QJBANBt8JY2LIGQF8o89qwUpRL5vbnKQ4IzZ5+TOl4RLR7O
    AQpJ81tGuINghO7aunctb6rrcKJrxmEH1whzComybrMCQQDKV49nOBudRBAIgG4K
    EnLzsRKISUHMZSJiYTYnablof8cKw1JaQduw7zgrUlLwnroSaAGX88+Jw1f5n2Lh
    Vlg5AkBDdUGnrDLtYBCDEQYZHblrkc7ZAeCllDOWjxUV+uMqlCv8A4Ey6omvY57C
    m6I8DkWVAQx8VPtozhvHjUw80rZHAkB55HWHAM3h13axKG0htCt7klhPsZHpx6MH
    EPjGlXIT+aW2XiPmK3ZlCDcWIenE+lmtbOpI159Wpk8BGXs/s/xBAkEAlAY3ymgx
    63BDJEwvOb2IaP8lDDxNsXx9XJNVvQbv5n15vNsLHbjslHfAhAbxnLQ1fLhUPqSi
    nNp/xedE1YxutQ==
    -----END PRIVATE KEY-----
    KEY
  end

  before do
    allow(Gitlab.config.pages).to receive(:enabled).and_return(true)
    project.add_role(user, role)
    sign_in(user)
    project.namespace.update(owner: user)
    allow_any_instance_of(Project).to receive(:pages_deployed?) { true }
  end

  context 'when the page_auto_ssl feature flag is enabled' do
    before do
      stub_feature_flags(pages_auto_ssl: true)
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
        expect(page).to have_content "The certificate will be shown here once it has been obtained from Let's Encrypt. This process may take up to an hour to complete."

        click_on 'Save Changes'

        expect(domain.reload.auto_ssl_enabled).to eq true
      end
    end

    context 'when the auto SSL management is initially enabled' do
      let(:domain) do
        create(:pages_domain, auto_ssl_enabled: true, project: project)
      end

      it 'disables auto SSL and dynamically updates the form accordingly', :js do
        visit edit_project_pages_domain_path(project, domain)

        expect(find("#pages_domain_auto_ssl_enabled", visible: false).value).to eq 'true'
        expect(page).to have_field 'Certificate (PEM)', type: 'textarea', disabled: true
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
  end

  context 'when the page_auto_ssl feature flag is disabled' do
    let(:domain) do
      create(:pages_domain, auto_ssl_enabled: false, project: project)
    end

    before do
      stub_feature_flags(pages_auto_ssl: false)

      visit edit_project_pages_domain_path(project, domain)
    end

    it "does not render the Let's Encrypt field", :js do
      expect(page).not_to have_selector '.js-auto-ssl-toggle-container'
    end
  end
end
