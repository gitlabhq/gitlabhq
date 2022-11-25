# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Upload a git lfs object', :js, feature_category: :source_code_management do
  include_context 'file upload requests helpers'

  let_it_be(:project) { create(:project) }
  let_it_be(:user) { project.first_owner }
  let_it_be(:personal_access_token) { create(:personal_access_token, user: user) }

  let(:file) { fixture_file_upload('spec/fixtures/banana_sample.gif') }
  let(:oid) { Digest::SHA256.hexdigest(File.read(file.path)) }
  let(:size) { file.size }
  let(:url) { capybara_url("/#{project.namespace.path}/#{project.path}.git/gitlab-lfs/objects/#{oid}/#{size}") }
  let(:headers) { { 'Content-Type' => 'application/octet-stream' } }

  subject do
    HTTParty.put(
      url,
      headers: headers,
      basic_auth: { username: user.username, password: personal_access_token.token },
      body: file.read
    )
  end

  before do
    stub_lfs_setting(enabled: true)
  end

  RSpec.shared_examples 'for a git lfs object' do
    it { expect { subject }.to change { LfsObject.count }.by(1) }
    it { expect(subject.code).to eq(200) }
  end

  it_behaves_like 'handling file uploads', 'for a git lfs object'
end
