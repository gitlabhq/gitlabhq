# frozen_string_literal: true

require 'spec_helper'
require 'gitlab/housekeeper/gitlab_client'

# rubocop:disable RSpec/MultipleMemoizedHelpers -- there are lots of parameters at play
RSpec.describe ::Gitlab::Housekeeper::GitlabClient do
  let(:client) { described_class.new }

  before do
    stub_env('HOUSEKEEPER_GITLAB_API_TOKEN', 'the-api-token')
  end

  describe '#non_housekeeper_changes' do
    let(:housekeeper_user_id) { 666 }

    let(:added_commit_note) do
      {
        id: 1698248524,
        body: "added 1 commit\n\n<ul><li>41b3a17f - Update stuff to test...",
        author: { "id" => 1234 },
        system: true
      }
    end

    let(:irrelevant_note1) do
      {
        id: 1698248523,
        body: "changed this line in ...",
        author: { "id" => 1234 },
        system: true
      }
    end

    let(:not_a_system_note) do
      {
        id: 1698248524,
        body: "added 1 commit\n\n<ul><li>41b3a17f - Update stuff to test...",
        author: { "id" => 1234 },
        system: false
      }
    end

    let(:updated_title_note) do
      {
        id: 1698248527,
        body: "changed title from **Add sharding{- -}key `namespace_id` to achievements**...",
        author: { "id" => 1235 },
        system: true
      }
    end

    let(:updated_description_note) do
      {
        id: 1698248530,
        body: "changed the description",
        author: { "id" => 1236 },
        system: true
      }
    end

    let(:notes) do
      [irrelevant_note1, not_a_system_note]
    end

    subject(:non_housekeeper_changes) do
      client.non_housekeeper_changes(
        source_project_id: 123,
        target_project_id: 456,
        source_branch: 'the-source-branch',
        target_branch: 'the-target-branch'
      )
    end

    before do
      # Get the current housekeeper user
      stub_request(:get, "https://gitlab.com/api/v4/user")
        .to_return(status: 200, body: { id: housekeeper_user_id }.to_json)

      # Get the id of the current merge request
      stub_request(:get, "https://gitlab.com/api/v4/projects/456/merge_requests?state=opened&source_branch=the-source-branch&target_branch=the-target-branch&source_project_id=123")
        .with(
          headers: {
            'Private-Token' => 'the-api-token'
          }
        )
        .to_return(status: 200, body: [{ iid: 8765 }].to_json)

      # Get the notes of the current merge request
      stub_request(:get, "https://gitlab.com/api/v4/projects/456/merge_requests/8765/notes?per_page=100")
        .with(
          headers: {
            'Private-Token' => 'the-api-token'
          }
        )
          .to_return(status: 200, body: notes.to_json)
    end

    it 'does not match irrelevant notes' do
      expect(non_housekeeper_changes).to eq([])
    end

    context 'when all important things change' do
      let(:notes) do
        [not_a_system_note, updated_title_note, updated_description_note, added_commit_note]
      end

      it 'returns :title, :description, :code' do
        expect(non_housekeeper_changes).to include(:title)
        expect(non_housekeeper_changes).to include(:description)
        expect(non_housekeeper_changes).to include(:code)
      end
    end

    context 'when title changes' do
      let(:notes) do
        [not_a_system_note, updated_title_note]
      end

      it 'returns :title, :description, :code' do
        expect(non_housekeeper_changes).to include(:title)
        expect(non_housekeeper_changes).not_to include(:description)
        expect(non_housekeeper_changes).not_to include(:code)
      end
    end

    context 'when description changes' do
      let(:notes) do
        [not_a_system_note, updated_description_note]
      end

      it 'returns :title, :description, :code' do
        expect(non_housekeeper_changes).not_to include(:title)
        expect(non_housekeeper_changes).to include(:description)
        expect(non_housekeeper_changes).not_to include(:code)
      end
    end

    context 'when the merge request does not exist' do
      it 'returns empty array' do
        expect(non_housekeeper_changes).to eq([])
      end
    end
  end

  describe '#create_or_update_merge_request' do
    let(:params) do
      {
        source_project_id: 123,
        title: 'A new merge request!',
        description: 'This merge request is pretty good.',
        source_branch: 'the-source-branch',
        target_branch: 'the-target-branch',
        target_project_id: 456,
        update_title: true,
        update_description: true
      }
    end

    let(:existing_mrs) { [] }

    before do
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

      context 'when update_title: false' do
        it 'does not update the title' do
          stub = stub_request(:put, "https://gitlab.com/api/v4/projects/456/merge_requests/1234")
            .with(
              body: {
                description: "This merge request is pretty good."
              }.to_json,
              headers: {
                'Content-Type' => 'application/json',
                'Private-Token' => 'the-api-token'
              }
            ).to_return(status: 200, body: "")

          client.create_or_update_merge_request(**params.merge(update_title: false))
          expect(stub).to have_been_requested
        end
      end

      context 'when update_description: false' do
        it 'does not update the description' do
          stub = stub_request(:put, "https://gitlab.com/api/v4/projects/456/merge_requests/1234")
            .with(
              body: {
                title: "A new merge request!"
              }.to_json,
              headers: {
                'Content-Type' => 'application/json',
                'Private-Token' => 'the-api-token'
              }
            ).to_return(status: 200, body: "")

          client.create_or_update_merge_request(**params.merge(update_description: false))
          expect(stub).to have_been_requested
        end
      end

      context 'when there is nothing to update' do
        it 'does not make a request' do
          client.create_or_update_merge_request(**params.merge(update_description: false, update_title: false))
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
# rubocop:enable RSpec/MultipleMemoizedHelpers
