require 'spec_helper'

describe API::Templates do
  files = {
    'Dockerfile/custom.dockerfile' => 'Custom dockerfiles',
    'gitignore/custom.gitignore'   => 'Custom gitignores',
    'gitlab-ci/custom.yml'         => 'Custom gitlab_ci_ymls',
    'LICENSE/custom.txt'           => 'Custom licenses'
  }

  set(:project) { create(:project, :custom_repo, files: files) }

  before do
    stub_ee_application_setting(file_template_project: project)
  end

  [
    :dockerfiles,
    :gitignores,
    :gitlab_ci_ymls,
    :licenses
  ].each do |type|
    describe "GET /templates/#{type}" do
      it 'includes the custom template in the response' do
        stub_licensed_features(custom_file_templates: true)
        get api("/templates/#{type}")

        expect(response).to have_gitlab_http_status(200)
        expect(json_response).to satisfy_one { |template| template['name'] == 'custom' }
      end

      it 'excludes the custom template when the feature is disabled' do
        stub_licensed_features(custom_file_templates: false)
        get api("/templates/#{type}")

        expect(response).to have_gitlab_http_status(200)
        expect(json_response).to satisfy_none { |template| template['name'] == 'custom' }
      end
    end

    describe "GET /templates/#{type}/custom" do
      it 'returns the custom template' do
        stub_licensed_features(custom_file_templates: true)
        get api("/templates/#{type}/custom")

        expect(response).to have_gitlab_http_status(200)
        expect(json_response['name']).to eq('custom')
        expect(json_response['content']).to eq("Custom #{type}")
      end

      it 'returns 404 when the feature is disabled' do
        stub_licensed_features(custom_file_templates: false)
        get api("/templates/#{type}/custom")

        expect(response).to have_gitlab_http_status(404)
      end
    end
  end
end
