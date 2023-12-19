# frozen_string_literal: true

require 'spec_helper'
require 'gitlab/housekeeper/gitlab_client'

RSpec.describe ::Gitlab::Housekeeper::GitlabClient do
  let(:client) { described_class.new }

  describe '#create_or_update_merge_request' do
    let(:params) do
      {
        source_project_id: 123,
        title: 'A new merge request!',
        description: 'This merge request is pretty good.',
        source_branch: 'the-source-branch',
        target_branch: 'the-target-branch',
        target_project_id: 456
      }
    end

    let(:existing_mrs) { [] }

    before do
      stub_env('HOUSEKEEPER_GITLAB_API_TOKEN', 'the-api-token')

      # Stub the check to see if the merge request already exists
      stub_request(:get, "https://gitlab.com/api/v4/projects/456/merge_requests?state=opened&source_branch=the-source-branch&target_branch=the-target-branch&source_project_id=123")
        .with(
          headers: {
            'Private-Token' => 'the-api-token'
          }
        )
        .to_return(status: 200, body: existing_mrs.to_json)
    end

    it 'calls the GitLab API passing the token' do
      stub = stub_request(:post, "https://gitlab.com/api/v4/projects/123/merge_requests")
        .with(
          body: {
            title: "A new merge request!",
            description: "This merge request is pretty good.",
            source_branch: "the-source-branch",
            target_branch: "the-target-branch",
            target_project_id: 456
          },
          headers: {
            'Content-Type' => 'application/json',
            'Private-Token' => 'the-api-token'
          })
        .to_return(status: 200, body: "")

      client.create_or_update_merge_request(**params)

      expect(stub).to have_been_requested
    end

    context 'when the merge request for the branch already exists' do
      let(:existing_mrs) do
        [{ iid: 1234 }]
      end

      it 'updates the merge request' do
        stub = stub_request(:put, "https://gitlab.com/api/v4/projects/456/merge_requests/1234")
          .with(
            body: {
              title: "A new merge request!",
              description: "This merge request is pretty good."
            }.to_json,
            headers: {
              'Content-Type' => 'application/json',
              'Private-Token' => 'the-api-token'
            })
         .to_return(status: 200, body: "")

        client.create_or_update_merge_request(**params)
        expect(stub).to have_been_requested
      end

      context 'when multiple merge requests exist' do
        let(:existing_mrs) do
          [{ iid: 1234 }, { iid: 5678 }]
        end

        it 'raises since we do not expect this to be possible' do
          expect { client.create_or_update_merge_request(**params) }.to raise_error(described_class::Error)
        end
      end
    end

    it 'raises an error when unsuccessful response' do
      stub_request(:post, "https://gitlab.com/api/v4/projects/123/merge_requests")
          .to_return(status: 400, body: "Real bad error")

      expect do
        client.create_or_update_merge_request(**params)
      end.to raise_error(described_class::Error, a_string_matching('Real bad error'))
    end
  end
end
