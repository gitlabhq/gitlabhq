# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Upload a group export archive', :with_current_organization, :api, :js, feature_category: :groups_and_projects do
  include_context 'file upload requests helpers'

  let_it_be(:user) { create(:user, :admin, organizations: [current_organization]) }
  let_it_be(:personal_access_token) { create(:personal_access_token, user: user) }

  let(:api_path) { '/groups/import' }
  let(:url) { capybara_url(api(api_path, personal_access_token: personal_access_token)) }
  let(:file) { fixture_file_upload('spec/fixtures/group_export.tar.gz') }

  subject do
    HTTParty.post(
      url,
      body: {
        path: 'test-import-group',
        name: 'test-import-group',
        file: file
      }
    )
  end

  RSpec.shared_examples 'for a group export archive' do
    it { expect { subject }.to change { Group.count }.by(1) }

    it { expect(subject.code).to eq(202) }
  end

  it_behaves_like 'handling file uploads', 'for a group export archive'
end
