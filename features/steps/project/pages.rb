class Spinach::Features::ProjectPages < Spinach::FeatureSteps
  include SharedAuthentication
  include SharedPaths
  include SharedProject

  step 'pages are enabled' do
    allow(Gitlab.config.pages).to receive(:enabled).and_return(true)
    allow(Gitlab.config.pages).to receive(:host).and_return('example.com')
    allow(Gitlab.config.pages).to receive(:port).and_return(80)
    allow(Gitlab.config.pages).to receive(:https).and_return(false)
  end

  step 'pages are disabled' do
    allow(Gitlab.config.pages).to receive(:enabled).and_return(false)
  end

  step 'I visit the Project Pages' do
    visit project_pages_path(@project)
  end

  step 'I should see the usage of GitLab Pages' do
    expect(page).to have_content('Configure pages')
  end

  step 'I should see the "Pages" tab' do
    page.within '.nav-sidebar' do
      expect(page).to have_link('Pages')
    end
  end

  step 'I should not see the "Pages" tab' do
    page.within '.nav-sidebar' do
      expect(page).not_to have_link('Pages')
    end
  end

  step 'pages are deployed' do
    pipeline = @project.pipelines.create(ref: 'HEAD',
                                         sha: @project.commit('HEAD').sha,
                                         source: :push,
                                         protected: false)

    build = build(:ci_build,
                  project: @project,
                  pipeline: pipeline,
                  ref: 'HEAD',
                  legacy_artifacts_file: fixture_file_upload(Rails.root + 'spec/fixtures/pages.zip'),
                  legacy_artifacts_metadata: fixture_file_upload(Rails.root + 'spec/fixtures/pages.zip.meta')
                 )

    result = ::Projects::UpdatePagesService.new(@project, build).execute
    expect(result[:status]).to eq(:success)
  end

  step 'I should be able to access the Pages' do
    expect(page).to have_content('Access pages')
  end

  step 'I should see that support for domains is disabled' do
    expect(page).to have_content('Support for domains and certificates is disabled')
  end

  step 'support for external domains is disabled' do
    allow(Gitlab.config.pages).to receive(:external_http).and_return(nil)
    allow(Gitlab.config.pages).to receive(:external_https).and_return(nil)
  end

  step 'pages are exposed on external HTTP address' do
    allow(Gitlab.config.pages).to receive(:external_http).and_return(['1.1.1.1:80'])
    allow(Gitlab.config.pages).to receive(:external_https).and_return(nil)
  end

  step 'pages are exposed on external HTTPS address' do
    allow(Gitlab.config.pages).to receive(:external_http).and_return(['1.1.1.1:80'])
    allow(Gitlab.config.pages).to receive(:external_https).and_return(['1.1.1.1:443'])
  end

  step 'I should be able to add a New Domain' do
    expect(page).to have_content('New Domain')
  end

  step 'I visit add a new Pages Domain' do
    visit new_project_pages_domain_path(@project)
  end

  step 'I fill the domain' do
    fill_in 'Domain', with: 'my.test.domain.com'
  end

  step 'I click on "Create New Domain"' do
    click_button 'Create New Domain'
  end

  step 'I should see a new domain added' do
    expect(page).to have_content('my.test.domain.com')
  end

  step 'pages domain is added' do
    @project.pages_domains.create!(domain: 'my.test.domain.com')
  end

  step 'I should see error message that domain already exists' do
    expect(page).to have_content('Domain has already been taken')
  end

  step 'I should see that support for certificates is disabled' do
    expect(page).to have_content('Support for custom certificates is disabled')
  end

  step 'I fill the certificate and key' do
    fill_in 'Certificate (PEM)', with: '-----BEGIN CERTIFICATE-----
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
-----END CERTIFICATE-----'

    fill_in 'Key (PEM)', with: '-----BEGIN PRIVATE KEY-----
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
-----END PRIVATE KEY-----'
  end

  step 'I click Remove Pages' do
    click_link 'Remove pages'
  end

  step 'The Pages should get removed' do
    expect(@project.pages_deployed?).to be_falsey
  end
end
