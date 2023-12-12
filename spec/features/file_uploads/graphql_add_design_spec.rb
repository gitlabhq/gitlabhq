# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Upload a design through graphQL', :js, feature_category: :design_management do
  include_context 'file upload requests helpers'

  let_it_be(:query) do
    "
      mutation uploadDesign($files: [Upload!]!, $projectPath: ID!, $iid: ID!) {
        designManagementUpload(input: { projectPath: $projectPath, iid: $iid, files: $files}) {
          clientMutationId,
          errors
        }
      }
    "
  end

  let_it_be(:user) { create(:user, :admin) }
  let_it_be(:personal_access_token) { create(:personal_access_token, user: user) }
  let_it_be(:design) { create(:design) }
  let_it_be(:map) { { "1": ["variables.files.0"] }.to_json }
  let_it_be(:operations) do
    {
      "operationName": "uploadDesign",
      "variables": {
        "files": [nil],
        "projectPath": design.project.full_path,
        "iid": design.issue.iid
      },
      "query": query
    }.to_json
  end

  let(:url) { capybara_url("/api/graphql?private_token=#{personal_access_token.token}") }
  let(:file) { fixture_file_upload('spec/fixtures/dk.png') }

  subject do
    HTTParty.post(
      url,
      body: {
        operations: operations,
        map: map,
        "1": file
      }
    )
  end

  before do
    stub_lfs_setting(enabled: true)
  end

  RSpec.shared_examples 'for a design upload through graphQL' do
    it 'creates proper objects' do
      expect { subject }
        .to change { DesignManagement::Design.count }.by(1)
        .and change { ::LfsObject.count }.by(1)
    end

    it { expect(subject.code).to eq(200) }
  end

  it_behaves_like 'handling file uploads', 'for a design upload through graphQL'
end
