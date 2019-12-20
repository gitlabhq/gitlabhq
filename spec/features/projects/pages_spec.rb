# frozen_string_literal: true
require 'spec_helper'

shared_examples 'pages settings editing' do
  let_it_be(:project) { create(:project, pages_https_only: false) }
  let(:user) { create(:user) }
  let(:role) { :maintainer }

  before do
    allow(Gitlab.config.pages).to receive(:enabled).and_return(true)

    project.add_role(user, role)

    sign_in(user)
  end

  context 'when user is the owner' do
    before do
      project.namespace.update(owner: user)
    end

    context 'when pages deployed' do
      before do
        allow_any_instance_of(Project).to receive(:pages_deployed?) { true }
      end

      it 'renders Access pages' do
        visit project_pages_path(project)

        expect(page).to have_content('Access pages')
      end

      context 'when pages are disabled in the project settings' do
        it 'renders disabled warning' do
          project.project_feature.update!(pages_access_level: ProjectFeature::DISABLED)

          visit project_pages_path(project)

          expect(page).to have_content('GitLab Pages are disabled for this project')
        end
      end

      it 'renders first deployment warning' do
        visit project_pages_path(project)

        expect(page).to have_content('It may take up to 30 minutes before the site is available after the first deployment.')
      end

      shared_examples 'does not render access control warning' do
        it 'does not render access control warning' do
          visit project_pages_path(project)

          expect(page).not_to have_content('Access Control is enabled for this Pages website')
        end
      end

      include_examples 'does not render access control warning'

      context 'when access control is enabled in gitlab settings' do
        before do
          stub_pages_setting(access_control: true)
        end

        it 'renders access control warning' do
          visit project_pages_path(project)

          expect(page).to have_content('Access Control is enabled for this Pages website')
        end

        context 'when pages are public' do
          before do
            project.project_feature.update!(pages_access_level: ProjectFeature::PUBLIC)
          end

          include_examples 'does not render access control warning'
        end
      end

      context 'when support for external domains is disabled' do
        it 'renders message that support is disabled' do
          visit project_pages_path(project)

          expect(page).to have_content('Support for domains and certificates is disabled')
        end
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

        it 'adds new domain with certificate' do
          visit new_project_pages_domain_path(project)

          fill_in 'Domain', with: 'my.test.domain.com'

          if ::Gitlab::LetsEncrypt.enabled?
            find('.js-auto-ssl-toggle-container .project-feature-toggle').click
          end

          fill_in 'Certificate (PEM)', with: certificate_pem
          fill_in 'Key (PEM)', with: certificate_key
          click_button 'Create New Domain'

          expect(page).to have_content('my.test.domain.com')
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

              if ::Gitlab::LetsEncrypt.enabled?
                find('.js-auto-ssl-toggle-container .project-feature-toggle').click
              end

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

    it 'does not see anything to destroy' do
      visit project_pages_path(project)

      expect(page).to have_content('Configure pages')
      expect(page).not_to have_link('Remove pages')
    end

    describe 'project settings page' do
      it 'renders "Pages" tab' do
        visit edit_project_path(project)

        page.within '.nav-sidebar' do
          expect(page).to have_link('Pages')
        end
      end

      context 'when pages are disabled' do
        before do
          allow(Gitlab.config.pages).to receive(:enabled).and_return(false)
        end

        it 'does not render "Pages" tab' do
          visit edit_project_path(project)

          page.within '.nav-sidebar' do
            expect(page).not_to have_link('Pages')
          end
        end
      end
    end
  end

  describe 'HTTPS settings', :https_pages_enabled do
    before do
      project.namespace.update(owner: user)

      allow_any_instance_of(Project).to receive(:pages_deployed?) { true }
    end

    it 'tries to change the setting' do
      visit project_pages_path(project)
      expect(page).to have_content("Force HTTPS (requires valid certificates)")

      uncheck :project_pages_https_only

      click_button 'Save'

      expect(page).to have_text('Your changes have been saved')
      expect(page).not_to have_checked_field('project_pages_https_only')
    end

    context 'setting could not be updated' do
      let(:service) { instance_double('Projects::UpdateService') }

      before do
        allow(Projects::UpdateService).to receive(:new).and_return(service)
        allow(service).to receive(:execute).and_return(status: :error, message: 'Some error has occured')
      end

      it 'tries to change the setting' do
        visit project_pages_path(project)

        uncheck :project_pages_https_only

        click_button 'Save'

        expect(page).to have_text('Some error has occured')
      end
    end

    context 'non-HTTPS domain exists' do
      let(:project) { create(:project, pages_https_only: false) }

      before do
        create(:pages_domain, :without_key, :without_certificate, project: project)
      end

      it 'the setting is disabled' do
        visit project_pages_path(project)

        expect(page).to have_field(:project_pages_https_only, disabled: true)
        expect(page).not_to have_button('Save')
      end
    end

    context 'HTTPS pages are disabled', :https_pages_disabled do
      it 'the setting is unavailable' do
        visit project_pages_path(project)

        expect(page).not_to have_field(:project_pages_https_only)
        expect(page).not_to have_content('Force HTTPS (requires valid certificates)')
        expect(page).not_to have_button('Save')
      end
    end
  end

  describe 'Remove page' do
    let(:project) { create :project, :repository }

    context 'when pages are deployed' do
      let(:pipeline) do
        commit_sha = project.commit('HEAD').sha

        project.ci_pipelines.create(
          ref: 'HEAD',
          sha: commit_sha,
          source: :push,
          protected: false
        )
      end

      let(:ci_build) do
        create(
          :ci_build,
          project: project,
          pipeline: pipeline,
          ref: 'HEAD')
      end

      let!(:artifact) do
        create(:ci_job_artifact, :archive,
               file: fixture_file_upload(File.join('spec/fixtures/pages.zip')), job: ci_build)
      end

      let!(:metadata) do
        create(:ci_job_artifact, :metadata,
               file: fixture_file_upload(File.join('spec/fixtures/pages.zip.meta')), job: ci_build)
      end

      before do
        result = Projects::UpdatePagesService.new(project, ci_build).execute
        expect(result[:status]).to eq(:success)
        expect(project).to be_pages_deployed
      end

      it 'removes the pages' do
        visit project_pages_path(project)

        expect(page).to have_link('Remove pages')

        accept_confirm { click_link 'Remove pages' }

        expect(page).to have_content('Pages were removed')
        expect(project.reload.pages_deployed?).to be_falsey
      end
    end
  end
end

describe 'Pages', :js do
  include LetsEncryptHelpers

  context 'when editing normally' do
    include_examples 'pages settings editing'
  end

  context 'when letsencrypt support is enabled' do
    before do
      stub_lets_encrypt_settings
    end

    include_examples 'pages settings editing'
  end
end
