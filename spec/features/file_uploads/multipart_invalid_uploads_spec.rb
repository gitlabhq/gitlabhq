# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Invalid uploads that must be rejected', :api, :js do
  include_context 'file upload requests helpers'

  let_it_be(:project) { create(:project) }
  let_it_be(:user) { create(:user, :admin) }
  let_it_be(:personal_access_token) { create(:personal_access_token, user: user) }

  context 'invalid upload key', :capybara_ignore_server_errors do
    let(:api_path) { "/projects/#{project.id}/packages/nuget/" }
    let(:url) { capybara_url(api(api_path)) }
    let(:file) { fixture_file_upload('spec/fixtures/dk.png') }

    subject do
      HTTParty.put(
        url,
        basic_auth: { user: user.username, password: personal_access_token.token },
        body: body
      )
    end

    RSpec.shared_examples 'by rejecting uploads with an invalid key' do
      RSpec.shared_examples 'rejecting invalid keys' do |key_name:|
        context "with invalid key #{key_name}" do
          let(:body) { { key_name => file, 'package[test][name]' => 'test' } }

          it { expect { subject }.not_to change { Packages::Package.nuget.count } }

          it { expect(subject.code).to eq(500) }

          it { expect(subject.body).to include("invalid field: \"#{key_name}\"") }
        end
      end

      it_behaves_like 'rejecting invalid keys', key_name: 'package[test'
      it_behaves_like 'rejecting invalid keys', key_name: 'package[]test'
      it_behaves_like 'rejecting invalid keys', key_name: '[]'
      it_behaves_like 'rejecting invalid keys', key_name: '[package]test'
      it_behaves_like 'rejecting invalid keys', key_name: 'package][test]]'
      it_behaves_like 'rejecting invalid keys', key_name: 'package[test[nested]]'
      it_behaves_like 'rejecting invalid keys', key_name: 'x' * 11000
    end

    it_behaves_like 'handling file uploads', 'by rejecting uploads with an invalid key'
  end
end
