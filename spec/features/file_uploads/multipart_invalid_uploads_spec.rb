# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Invalid uploads that must be rejected', :api, :js, feature_category: :package_registry do
  include_context 'file upload requests helpers'

  let_it_be(:project) { create(:project) }
  let_it_be(:user) { project.owner }
  let_it_be(:personal_access_token) { create(:personal_access_token, user: user) }

  context 'invalid upload key', :capybara_ignore_server_errors do
    let(:api_path) { "/projects/#{project.id}/packages/nuget/" }
    let(:url) { capybara_url(api(api_path)) }
    let(:file) { fixture_file_upload('spec/fixtures/dk.png') }

    subject do
      HTTParty.put(
        url,
        basic_auth: { username: user.username, password: personal_access_token.token },
        body: body
      )
    end

    RSpec.shared_examples 'rejecting invalid keys' do |key_name:, message: nil, status: 500|
      context "with invalid key #{key_name}" do
        let(:body) { { key_name => file, 'package[test][name]' => 'test' } }

        it { expect { subject }.not_to change { Packages::Package.nuget.count } }

        it { expect(subject.code).to eq(status) }

        it { expect(subject.body).to include(message.presence || "invalid field: \"#{key_name}\"") }
      end
    end

    RSpec.shared_examples 'by rejecting uploads with an invalid key' do
      it_behaves_like 'rejecting invalid keys', key_name: 'package[test'
      it_behaves_like 'rejecting invalid keys', key_name: '[]'
      it_behaves_like 'rejecting invalid keys', key_name: '[package]test'
      it_behaves_like 'rejecting invalid keys', key_name: 'package][test]]'
      it_behaves_like 'rejecting invalid keys', key_name: 'package[test[nested]]'
    end

    # These keys are rejected directly by rack itself.
    # The request will not be received by multipart.rb (can't use the 'handling file uploads' shared example)
    it_behaves_like 'rejecting invalid keys', key_name: 'x' * 11000, status: 400, message: 'Bad Request'
    it_behaves_like 'rejecting invalid keys', key_name: 'package[]test', status: 400, message: 'Bad Request'

    it_behaves_like 'handling file uploads', 'by rejecting uploads with an invalid key'
  end
end
