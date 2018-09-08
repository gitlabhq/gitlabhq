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
    "008f43ba78b7912f7bf7ef1d7c3b8a0e5ae14a759dfa refs/heads/masterreport-status delete-refs side-band-64k quiet atomic ofs-delta agent=git/2.18.0
0000"
  end

  let(:base_headers) do
    {
      'Geo-GL-Id' => "key-#{key.id}",
      'Authorization' => 'secret'
    }
  end

  let(:data) do
    {
      'gl_id' => "key-#{key.id}",
      'primary_repo' => "#{primary_node.url}#{project.repository.full_path}.git"
    }
  end

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
        end.to raise_error(described_class::MustBeASecondaryNode)
      end
    end

    context 'against secondary node' do
      let(:current_node) { secondary_node }

      let(:full_info_refs_url) { "#{primary_node.url}#{project.full_path}.git/info/refs?service=git-receive-pack" }
      let(:info_refs_headers) { base_headers.merge('Content-Type' => 'application/x-git-upload-pack-request') }
      let(:info_refs_http_body_full) do
        "001f# service=git-receive-pack
0000#{info_refs_body_short}"
      end

      before do
        stub_request(:get, full_info_refs_url).to_return(status: 200, body: info_refs_http_body_full, headers: info_refs_headers)
      end

      it 'returns a Net::HTTPOK' do
        expect(subject.info_refs).to be_a(Net::HTTPOK)
      end

      it 'returns a modified body' do
        expect(subject.info_refs.body).to eql(info_refs_body_short)
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

      let(:full_git_receive_pack_url) { "#{primary_node.url}#{project.full_path}.git/git-receive-pack" }
      let(:push_headers) do
        base_headers.merge(
          'Content-Type' => 'application/x-git-receive-pack-request',
          'Accept' => 'application/x-git-receive-pack-result'
        )
      end

      before do
        stub_request(:post, full_git_receive_pack_url).to_return(status: 201, body: info_refs_body_short, headers: push_headers)
      end

      it 'returns a Net::HTTPCreated' do
        expect(subject.push(info_refs_body_short)).to be_a(Net::HTTPCreated)
      end
    end
  end
end
