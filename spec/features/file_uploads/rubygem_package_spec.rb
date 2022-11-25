# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Upload a RubyGems package', :api, :js, feature_category: :package_registry do
  include_context 'file upload requests helpers'

  let_it_be(:project) { create(:project) }
  let_it_be(:user) { project.first_owner }
  let_it_be(:personal_access_token) { create(:personal_access_token, user: user) }

  let(:api_path) { "/projects/#{project_id}/packages/rubygems/api/v1/gems" }
  let(:url) { capybara_url(api(api_path)) }
  let(:file) { fixture_file_upload('spec/fixtures/dk.png') }

  subject do
    HTTParty.post(
      url,
      headers: { 'Authorization' => personal_access_token.token },
      body: { file: file }
    )
  end

  shared_examples 'for a Rubygems package' do
    it 'creates package files' do
      expect { subject }
        .to change { Packages::Package.rubygems.count }.by(1)
        .and change { Packages::PackageFile.count }.by(1)
    end

    it { expect(subject.code).to eq(201) }
  end

  context 'with an integer project ID' do
    let(:project_id) { project.id }

    it_behaves_like 'handling file uploads', 'for a Rubygems package'
  end

  context 'with an encoded project ID' do
    let(:project_id) { "#{project.namespace.path}%2F#{project.path}" }

    it_behaves_like 'handling file uploads', 'for a Rubygems package'
  end
end
