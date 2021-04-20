# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Upload a nuget package', :api, :js do
  include_context 'file upload requests helpers'

  let_it_be(:project) { create(:project) }
  let_it_be(:user) { project.owner }
  let_it_be(:personal_access_token) { create(:personal_access_token, user: user) }

  let(:api_path) { "/projects/#{project.id}/packages/nuget/" }
  let(:url) { capybara_url(api(api_path)) }
  let(:file) { fixture_file_upload('spec/fixtures/dk.png') }

  subject do
    HTTParty.put(
      url,
      basic_auth: { username: user.username, password: personal_access_token.token },
      body: { package: file }
    )
  end

  shared_examples 'for a nuget package' do
    it 'creates package files' do
      expect { subject }
        .to change { Packages::Package.nuget.count }.by(1)
        .and change { Packages::PackageFile.count }.by(1)
    end

    it { expect(subject.code).to eq(201) }
  end

  it_behaves_like 'handling file uploads', 'for a nuget package'
end
