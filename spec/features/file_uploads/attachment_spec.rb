# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Upload an attachment', :api, :js do
  include_context 'file upload requests helpers'

  let_it_be(:project) { create(:project) }
  let_it_be(:user) { project.owner }
  let_it_be(:personal_access_token) { create(:personal_access_token, user: user) }

  let(:api_path) { "/projects/#{project_id}/uploads" }
  let(:url) { capybara_url(api(api_path)) }
  let(:file) { fixture_file_upload('spec/fixtures/dk.png') }

  subject do
    HTTParty.post(
      url,
      headers: { 'PRIVATE-TOKEN' => personal_access_token.token },
      body: { file: file }
    )
  end

  shared_examples 'for an attachment' do
    it 'creates files' do
      expect { subject }
        .to change { Upload.count }.by(1)
    end

    it { expect(subject.code).to eq(201) }
  end

  context 'with an integer project ID' do
    let(:project_id) { project.id }

    it_behaves_like 'handling file uploads', 'for an attachment'
  end

  context 'with an encoded project ID' do
    let(:project_id) { "#{project.namespace.path}%2F#{project.path}" }

    it_behaves_like 'handling file uploads', 'for an attachment'
  end
end
