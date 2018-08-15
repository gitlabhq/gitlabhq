require 'spec_helper'

describe API::Settings, 'EE Settings' do
  include StubENV

  let(:user) { create(:user) }
  let(:admin) { create(:admin) }
  let(:project) { create(:project) }

  before do
    stub_env('IN_MEMORY_APPLICATION_SETTINGS', 'false')
  end

  describe "PUT /application/settings" do
    it 'sets EE specific settings' do
      stub_licensed_features(custom_file_templates: true)

      put api("/application/settings", admin),
        help_text: 'Help text',
        snowplow_collector_uri: 'https://snowplow.example.com',
        snowplow_cookie_domain: '.example.com',
        snowplow_enabled: true,
        snowplow_site_id:  'site_id',
        file_template_project_id: project.id

      expect(response).to have_gitlab_http_status(200)
      expect(json_response['help_text']).to eq('Help text')
      expect(json_response['snowplow_collector_uri']).to eq('https://snowplow.example.com')
      expect(json_response['snowplow_cookie_domain']).to eq('.example.com')
      expect(json_response['snowplow_enabled']).to be_truthy
      expect(json_response['snowplow_site_id']).to eq('site_id')
      expect(json_response['file_template_project_id']).to eq(project.id)
    end
  end

  shared_examples 'settings for licensed features' do
    let(:attribute_names) { settings.keys.map(&:to_s) }

    before do
      # Make sure the settings exist before the specs
      get api("/application/settings", admin)
    end

    context 'when the feature is not available' do
      before do
        stub_licensed_features(feature => false)
      end

      it 'hides the attributes in the API' do
        get api("/application/settings", admin)

        expect(response).to have_gitlab_http_status(200)
        attribute_names.each do |attribute|
          expect(json_response.keys).not_to include(attribute)
        end
      end

      it 'does not update application settings' do
        expect { put api("/application/settings", admin), settings }
          .not_to change { ApplicationSetting.current.reload.attributes.slice(*attribute_names) }
      end
    end

    context 'when the feature is available' do
      before do
        stub_licensed_features(feature => true)
      end

      it 'includes the attributes in the API' do
        get api("/application/settings", admin)

        expect(response).to have_gitlab_http_status(200)
        attribute_names.each do |attribute|
          expect(json_response.keys).to include(attribute)
        end
      end

      it 'allows updating the settings' do
        put api("/application/settings", admin), settings
        expect(response).to have_gitlab_http_status(200)

        settings.each do |attribute, value|
          expect(ApplicationSetting.current.public_send(attribute)).to eq(value)
        end
      end
    end
  end

  context 'mirroring settings' do
    let(:settings) { { mirror_max_capacity: 15 } }
    let(:feature) { :repository_mirrors }

    it_behaves_like 'settings for licensed features'
  end

  context 'external policy classification settings' do
    let(:settings) do
      {
        external_authorization_service_enabled: true,
        external_authorization_service_url: 'https://custom.service/',
        external_authorization_service_default_label: 'default',
        external_authorization_service_timeout: 9.99,
        external_auth_client_cert: File.read('ee/spec/fixtures/passphrase_x509_certificate.crt'),
        external_auth_client_key: File.read('ee/spec/fixtures/passphrase_x509_certificate_pk.key'),
        external_auth_client_key_pass: "5iveL!fe"
      }
    end
    let(:feature) { :external_authorization_service }

    it_behaves_like 'settings for licensed features'
  end

  context 'custom email footer' do
    let(:settings) { { email_additional_text: 'this is a scary legal footer' } }
    let(:feature) { :email_additional_text }

    it_behaves_like 'settings for licensed features'
  end

  context 'custom file template project' do
    let(:settings) { { file_template_project_id: project.id } }
    let(:feature) { :custom_file_templates }

    it_behaves_like 'settings for licensed features'
  end

  context "missing snowplow_collector_uri value when snowplow_enabled is true" do
    it "returns a blank parameter error message" do
      put api("/application/settings", admin), snowplow_enabled: true

      expect(response).to have_gitlab_http_status(400)
      expect(json_response['error']).to eq('snowplow_collector_uri is missing')
    end
  end
end
