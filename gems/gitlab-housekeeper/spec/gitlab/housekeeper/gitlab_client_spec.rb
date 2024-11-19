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

    let(:added_assignee_note) do
      {
        id: 1698248524,
        body: "assigned to @gitlab-bot",
        author: { "id" => 1234 },
        system: true
      }
    end

    let(:removed_assignee_note) do
      {
        id: 1698248524,
        body: "unassigned @gitlab-bot",
        author: { "id" => 1234 },
        system: true
      }
    end

    let(:added_reviewer_note) do
      {
        id: 1698248524,
        body: "requested review from @bob",
        author: { "id" => 1234 },
        system: true
      }
    end

    let(:removed_reviewer_note) do
      {
        id: 1698248524,
        body: "removed review request for @bob",
        author: { "id" => 1234 },
        system: true
      }
    end

    let(:approved_note) do
      {
        id: 1698248524,
        body: "approved this merge request",
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

    let(:added_label_event) do
      {
        id: 274504558,
        user: { id: 18645100 },
        label: { id: 2492649, name: "good label" },
        action: "add"
      }
    end

    let(:removed_label_event) do
      {
        id: 274504558,
        user: { id: 18645100 },
        label: { id: 2492649, name: "bad label" },
        action: "remove"
      }
    end

    let(:resource_label_events) do
      [added_label_event]
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
        .with(
          headers: {
            'Private-Token' => 'the-api-token'
          }
        )
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

      # Get the label changes for the merge request
      stub_request(:get, "https://gitlab.com/api/v4/projects/456/merge_requests/8765/resource_label_events?per_page=100")
        .with(
          headers: {
            'Private-Token' => 'the-api-token'
          }
        )
        .to_return(status: 200, body: resource_label_events.to_json)
    end

    it 'does not match irrelevant notes' do
      expect(non_housekeeper_changes).to eq([])
    end

    context 'when all important things change' do
      let(:notes) do
        [not_a_system_note, updated_title_note, updated_description_note, added_commit_note, added_reviewer_note,
          added_assignee_note, approved_note]
      end

      let(:resource_label_events) do
        [removed_label_event]
      end

      it 'returns :title, :description, :code, :labels, :assignees, :reviewers, :approvals' do
        expect(non_housekeeper_changes).to match_array([
          :title,
          :description,
          :code,
          :labels,
          :assignees,
          :reviewers,
          :approvals
        ])
      end
    end

    context 'when title changes' do
      let(:notes) do
        [not_a_system_note, updated_title_note]
      end

      it 'returns :title' do
        expect(non_housekeeper_changes).to match_array([:title])
      end
    end

    context 'when description changes' do
      let(:notes) do
        [not_a_system_note, updated_description_note]
      end

      it 'returns :description' do
        expect(non_housekeeper_changes).to match_array([:description])
      end
    end

    context 'when labels change' do
      let(:notes) do
        [not_a_system_note]
      end

      let(:resource_label_events) do
        [added_label_event, removed_label_event]
      end

      it 'returns :labels' do
        expect(non_housekeeper_changes).to match_array([:labels])
      end
    end

    context 'when assignees are added' do
      let(:notes) do
        [not_a_system_note, added_assignee_note]
      end

      it 'returns :assignees' do
        expect(non_housekeeper_changes).to match_array([:assignees])
      end
    end

    context 'when assignees are removed' do
      let(:notes) do
        [not_a_system_note, removed_assignee_note]
      end

      it 'returns :assignees' do
        expect(non_housekeeper_changes).to match_array([:assignees])
      end
    end

    context 'when approvals change' do
      let(:notes) do
        [not_a_system_note, approved_note]
      end

      it 'returns :approvals' do
        expect(non_housekeeper_changes).to match_array([:approvals])
      end
    end

    context 'when reviewers are added' do
      let(:notes) do
        [not_a_system_note, added_reviewer_note]
      end

      it 'returns :reviewers' do
        expect(non_housekeeper_changes).to match_array([:reviewers])
      end
    end

    context 'when reviewers are removed' do
      let(:notes) do
        [not_a_system_note, removed_reviewer_note]
      end

      it 'returns :reviewers' do
        expect(non_housekeeper_changes).to match_array([:reviewers])
      end
    end

    context 'when the merge request does not exist' do
      it 'returns empty array' do
        expect(non_housekeeper_changes).to eq([])
      end
    end

    context 'when the event user is nil' do
      let(:resource_label_events) do
        [{ id: 274504558, user: nil, label: { id: 2492649, name: "good label" }, action: "add" }]
      end

      it 'does not raise an error and return an empty array' do
        expect(non_housekeeper_changes).to eq([])
      end
    end
  end

  describe '#create_or_update_merge_request' do
    let(:assignee_id) { 111 }
    let(:reviewer_id) { 999 }

    let(:change) do
      create_change
    end

    let(:params) do
      {
        change: change,
        source_project_id: 123,
        source_branch: 'the-source-branch',
        target_branch: 'the-target-branch',
        target_project_id: 456
      }
    end

    let(:existing_mrs) { [] }

    before do
      # Stub the user id of the reviewers and assignees
      stub_request(:get, "https://gitlab.com/api/v4/users")
        .with(
          query: { username: 'thegitlabreviewer' },
          headers: {
            'Private-Token' => 'the-api-token'
          }
        )
        .to_return(status: 200, body: [{ id: reviewer_id }].to_json)
      stub_request(:get, "https://gitlab.com/api/v4/users")
        .with(
          query: { username: 'thegitlabassignee' },
          headers: {
            'Private-Token' => 'the-api-token'
          }
        )
        .to_return(status: 200, body: [{ id: assignee_id }].to_json)

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
      api_response = {
        iid: 5678,
        web_url: 'https://example.com/api/v4/merge_requests/abc123/5678'
      }
      stub = stub_request(:post, "https://gitlab.com/api/v4/projects/123/merge_requests")
        .with(
          body: {
            title: "The change title",
            description: change.mr_description,
            labels: "some-label-1,some-label-2",
            source_branch: "the-source-branch",
            target_branch: "the-target-branch",
            target_project_id: 456,
            remove_source_branch: true,
            assignee_ids: [assignee_id],
            reviewer_ids: [reviewer_id],
            squash: true
          },
          headers: {
            'Content-Type' => 'application/json',
            'Private-Token' => 'the-api-token'
          })
            .to_return(status: 200, body: api_response.to_json)

      result = client.create_or_update_merge_request(**params)

      expect(stub).to have_been_requested

      expect(result['iid']).to eq(5678)
      expect(result['web_url']).to eq('https://example.com/api/v4/merge_requests/abc123/5678')
    end

    context 'when the merge request for the branch already exists' do
      let(:existing_mrs) do
        [{ iid: 1234 }]
      end

      it 'updates the merge request' do
        api_response = {
          iid: 1234,
          web_url: 'https://example.com/api/v4/merge_requests/abc123/1234'
        }
        stub = stub_request(:put, "https://gitlab.com/api/v4/projects/456/merge_requests/1234")
          .with(
            body: {
              title: "The change title",
              description: change.mr_description,
              add_labels: "some-label-1,some-label-2",
              assignee_ids: [assignee_id],
              reviewer_ids: [reviewer_id]
            }.to_json,
            headers: {
              'Content-Type' => 'application/json',
              'Private-Token' => 'the-api-token'
            })
         .to_return(status: 200, body: api_response.to_json)

        result = client.create_or_update_merge_request(**params)
        expect(stub).to have_been_requested

        expect(result['iid']).to eq(1234)
        expect(result['web_url']).to eq('https://example.com/api/v4/merge_requests/abc123/1234')
      end

      context 'when multiple merge requests exist' do
        let(:existing_mrs) do
          [{ iid: 1234 }, { iid: 5678 }]
        end

        it 'raises since we do not expect this to be possible' do
          expect { client.create_or_update_merge_request(**params) }.to raise_error(described_class::Error)
        end
      end

      context 'when the merge request has been updated by a non-housekeeper user' do
        let(:change) do
          create_change(non_housekeeper_changes: non_housekeeper_changes)
        end

        context 'when the title has changed' do
          let(:non_housekeeper_changes) { [:title] }

          it 'does not update the title' do
            stub = stub_request(:put, "https://gitlab.com/api/v4/projects/456/merge_requests/1234")
              .with(
                body: {
                  description: change.mr_description,
                  add_labels: "some-label-1,some-label-2",
                  assignee_ids: [assignee_id],
                  reviewer_ids: [reviewer_id]
                }.to_json,
                headers: {
                  'Content-Type' => 'application/json',
                  'Private-Token' => 'the-api-token'
                }
              ).to_return(status: 200, body: '{}')

            client.create_or_update_merge_request(**params)
            expect(stub).to have_been_requested
          end
        end

        context 'when the description has changed' do
          let(:non_housekeeper_changes) { [:description] }

          it 'does not update the description' do
            stub = stub_request(:put, "https://gitlab.com/api/v4/projects/456/merge_requests/1234")
              .with(
                body: {
                  title: "The change title",
                  add_labels: "some-label-1,some-label-2",
                  assignee_ids: [assignee_id],
                  reviewer_ids: [reviewer_id]
                }.to_json,
                headers: {
                  'Content-Type' => 'application/json',
                  'Private-Token' => 'the-api-token'
                }
              ).to_return(status: 200, body: '{}')

            client.create_or_update_merge_request(**params)
            expect(stub).to have_been_requested
          end
        end

        context 'when labels have changed' do
          let(:non_housekeeper_changes) { [:labels] }

          it 'does not update the labels' do
            stub = stub_request(:put, "https://gitlab.com/api/v4/projects/456/merge_requests/1234")
              .with(
                body: {
                  title: "The change title",
                  description: change.mr_description,
                  assignee_ids: [assignee_id],
                  reviewer_ids: [reviewer_id]
                }.to_json,
                headers: {
                  'Content-Type' => 'application/json',
                  'Private-Token' => 'the-api-token'
                }
              ).to_return(status: 200, body: '{}')

            client.create_or_update_merge_request(**params)
            expect(stub).to have_been_requested
          end
        end

        context 'when reviewers have changed' do
          let(:non_housekeeper_changes) { [:reviewers] }

          it 'does not update the reviewers' do
            stub = stub_request(:put, "https://gitlab.com/api/v4/projects/456/merge_requests/1234")
              .with(
                body: {
                  title: "The change title",
                  description: change.mr_description,
                  add_labels: "some-label-1,some-label-2",
                  assignee_ids: [assignee_id]
                }.to_json,
                headers: {
                  'Content-Type' => 'application/json',
                  'Private-Token' => 'the-api-token'
                }
              ).to_return(status: 200, body: '{}')

            client.create_or_update_merge_request(**params)
            expect(stub).to have_been_requested
          end
        end

        context 'when assignees have changed' do
          let(:non_housekeeper_changes) { [:assignees] }

          it 'does not update the assignees' do
            stub = stub_request(:put, "https://gitlab.com/api/v4/projects/456/merge_requests/1234")
              .with(
                body: {
                  title: "The change title",
                  description: change.mr_description,
                  add_labels: "some-label-1,some-label-2",
                  reviewer_ids: [reviewer_id]
                }.to_json,
                headers: {
                  'Content-Type' => 'application/json',
                  'Private-Token' => 'the-api-token'
                }
              ).to_return(status: 200, body: '{}')

            client.create_or_update_merge_request(**params)
            expect(stub).to have_been_requested
          end
        end

        context 'when there is nothing to update' do
          let(:non_housekeeper_changes) { [:title, :description, :labels, :assignees, :reviewers] }

          it 'does not make a request' do
            client.create_or_update_merge_request(**params)
          end
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
