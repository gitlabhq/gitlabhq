# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Geo::GitPushSSHProxy, :geo do
  include ::EE::GeoHelpers

  set(:primary_node) { create(:geo_node, :primary) }
  set(:secondary_node) { create(:geo_node) }

  let(:current_node) { nil }
  let(:project) { create(:project, :repository) }
  let(:user) { project.creator }
  let(:key) { create(:key, user: user) }
  let(:base_request) { double(Gitlab::Geo::BaseRequest.new.authorization) }

  let(:info_refs_body_short) do
    "008f43ba78b7912f7bf7ef1d7c3b8a0e5ae14a759dfa refs/heads/masterreport-status delete-refs side-band-64k quiet atomic ofs-delta agent=git/2.18.0\n0000"
  end

  let(:base_headers) do
    {
      'Geo-GL-Id' => "key-#{key.id}",
      'Authorization' => 'secret'
    }
  end

  let(:primary_repo_http) { geo_primary_http_url_to_repo(project) }
  let(:primary_repo_ssh) { geo_primary_ssh_url_to_repo(project) }

  let(:data) do
    {
      'gl_id' => "key-#{key.id}",
      'primary_repo' => primary_repo_http
    }
  end

  describe '.inform_client_message' do
    it 'returns a message, with the ssh address' do
      expect(described_class.inform_client_message(primary_repo_ssh)).to eql("You're pushing to a Geo secondary.\nWe'll help you by proxying this request to the primary: #{primary_repo_ssh}")
    end
  end

  context 'instance methods' do
    subject { described_class.new(data) }

    before do
      stub_current_geo_node(current_node)

      allow(Gitlab::Geo::BaseRequest).to receive(:new).and_return(base_request)
      allow(base_request).to receive(:authorization).and_return('secret')
    end

    describe '#info_refs' do
      context 'against primary node' do
        let(:current_node) { primary_node }

        it 'raises an exception' do
          expect do
            subject.info_refs
          end.to raise_error(described_class::MustBeASecondaryNode, 'Node is not a secondary or there is no primary Geo node')
        end
      end

      context 'against secondary node' do
        let(:current_node) { secondary_node }

        let(:full_info_refs_url) { "#{primary_repo_http}/info/refs?service=git-receive-pack" }
        let(:info_refs_headers) { base_headers.merge('Content-Type' => 'application/x-git-upload-pack-request') }
        let(:info_refs_http_body_full) { "001f# service=git-receive-pack\n0000#{info_refs_body_short}" }

        context 'with a failed response' do
          let(:error_msg) { 'execution expired' }

          before do
            stub_request(:get, full_info_refs_url).to_timeout
          end

          it 'returns a Gitlab::Geo::GitPushSSHProxy::FailedAPIResponse' do
            expect(subject.info_refs).to be_a(Gitlab::Geo::GitPushSSHProxy::FailedAPIResponse)
          end

          it 'has a code of 500' do
            expect(subject.info_refs.code).to be(500)
          end

          it 'has a status of false' do
            expect(subject.info_refs.body[:status]).to be_falsey
          end

          it 'has a messsage' do
            expect(subject.info_refs.body[:message]).to eql("Failed to contact primary #{primary_repo_http}\nError: #{error_msg}")
          end

          it 'has no result' do
            expect(subject.info_refs.body[:result]).to be_nil
          end
        end

        context 'with an invalid response' do
          let(:error_msg) { 'dial unix /Users/ash/src/gdk/gdk-ee/gitlab.socket: connect: connection refused' }

          before do
            stub_request(:get, full_info_refs_url).to_return(status: 502, body: error_msg, headers: info_refs_headers)
          end

          it 'returns a Gitlab::Geo::GitPushSSHProxy::FailedAPIResponse' do
            expect(subject.info_refs).to be_a(Gitlab::Geo::GitPushSSHProxy::APIResponse)
          end

          it 'has a code of 502' do
            expect(subject.info_refs.code).to be(502)
          end

          it 'has a status of false' do
            expect(subject.info_refs.body[:status]).to be_falsey
          end

          it 'has a messsage' do
            expect(subject.info_refs.body[:message]).to eql("Failed to contact primary #{primary_repo_http}\nError: #{error_msg}")
          end

          it 'has no result' do
            expect(subject.info_refs.body[:result]).to be_nil
          end
        end

        context 'with a valid response' do
          before do
            stub_request(:get, full_info_refs_url).to_return(status: 200, body: info_refs_http_body_full, headers: info_refs_headers)
          end

          it 'returns a Gitlab::Geo::GitPushSSHProxy::APIResponse' do
            expect(subject.info_refs).to be_a(Gitlab::Geo::GitPushSSHProxy::APIResponse)
          end

          it 'has a code of 200' do
            expect(subject.info_refs.code).to be(200)
          end

          it 'has a status of true' do
            expect(subject.info_refs.body[:status]).to be_truthy
          end

          it 'has no messsage' do
            expect(subject.info_refs.body[:message]).to be_nil
          end

          it 'returns a modified body' do
            expect(subject.info_refs.body[:result]).to eql(Base64.encode64(info_refs_body_short))
          end
        end
      end
    end

    describe '#push' do
      context 'against primary node' do
        let(:current_node) { primary_node }

        it 'raises an exception' do
          expect do
            subject.push(info_refs_body_short)
          end.to raise_error(described_class::MustBeASecondaryNode)
        end
      end

      context 'against secondary node' do
        let(:current_node) { secondary_node }

        let(:full_git_receive_pack_url) { "#{primary_repo_http}/git-receive-pack" }
        let(:push_headers) do
          base_headers.merge(
            'Content-Type' => 'application/x-git-receive-pack-request',
            'Accept' => 'application/x-git-receive-pack-result'
          )
        end

        context 'with a failed response' do
          let(:error_msg) { 'execution expired' }

          before do
            stub_request(:post, full_git_receive_pack_url).to_timeout
          end

          it 'returns a Gitlab::Geo::GitPushSSHProxy::FailedAPIResponse' do
            expect(subject.push(info_refs_body_short)).to be_a(Gitlab::Geo::GitPushSSHProxy::FailedAPIResponse)
          end

          it 'has a messsage' do
            expect(subject.push(info_refs_body_short).body[:message]).to eql("Failed to contact primary #{primary_repo_http}\nError: #{error_msg}")
          end

          it 'has no result' do
            expect(subject.push(info_refs_body_short).body[:result]).to be_nil
          end
        end

        context 'with an invalid response' do
          let(:error_msg) { 'dial unix /Users/ash/src/gdk/gdk-ee/gitlab.socket: connect: connection refused' }

          before do
            stub_request(:post, full_git_receive_pack_url).to_return(status: 502, body: error_msg, headers: push_headers)
          end

          it 'returns a Gitlab::Geo::GitPushSSHProxy::FailedAPIResponse' do
            expect(subject.push(info_refs_body_short)).to be_a(Gitlab::Geo::GitPushSSHProxy::APIResponse)
          end

          it 'has a messsage' do
            expect(subject.push(info_refs_body_short).body[:message]).to eql("Failed to contact primary #{primary_repo_http}\nError: #{error_msg}")
          end

          it 'has no result' do
            expect(subject.push(info_refs_body_short).body[:result]).to be_nil
          end
        end

        context 'with a valid response' do
          let(:body) { '<binary content>' }
          let(:base64_encoded_body) { Base64.encode64(body) }

          before do
            stub_request(:post, full_git_receive_pack_url).to_return(status: 201, body: body, headers: push_headers)
          end

          it 'returns a Gitlab::Geo::GitPushSSHProxy::APIResponse' do
            expect(subject.push(info_refs_body_short)).to be_a(Gitlab::Geo::GitPushSSHProxy::APIResponse)
          end

          it 'has a code of 201' do
            expect(subject.push(info_refs_body_short).code).to be(201)
          end

          it 'has no messsage' do
            expect(subject.push(info_refs_body_short).body[:message]).to be_nil
          end

          it 'has a result' do
            expect(subject.push(info_refs_body_short).body[:result]).to eql(base64_encoded_body)
          end
        end
      end
    end
  end
end
