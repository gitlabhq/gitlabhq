# frozen_string_literal: true

require 'spec_helper'
require 'gitlab/housekeeper/merge_request_manager'

# rubocop:disable RSpec/MultipleMemoizedHelpers -- there are lots of parameters at play
RSpec.describe ::Gitlab::Housekeeper::MergeRequestManager do
  let(:git) { instance_double(::Gitlab::Housekeeper::Git) }
  let(:gitlab_client) { instance_double(::Gitlab::Housekeeper::GitlabClient) }
  let(:branch_name) { 'the-branch' }
  let(:keep) { instance_double(::Gitlab::Housekeeper::Keep) }
  let(:change) { create_change(identifiers: %w[the change]) }

  let(:manager) do
    described_class.new(
      git: git,
      target_branch: 'master',
      push_when_approved: false,
      push_when_conflict: true
    )
  end

  let(:project_scope) do
    {
      source_project_id: '123',
      source_branch: branch_name,
      target_branch: 'master',
      target_project_id: '456'
    }
  end

  before do
    stub_env('HOUSEKEEPER_FORK_PROJECT_ID', '123')
    stub_env('HOUSEKEEPER_TARGET_PROJECT_ID', '456')

    allow(::Gitlab::Housekeeper::GitlabClient).to receive(:new).and_return(gitlab_client)
  end

  describe 'project ids' do
    context 'when HOUSEKEEPER_FORK_PROJECT_ID env var is set' do
      it 'uses the fork project id as the source' do
        expect(gitlab_client).to receive(:closed_merge_request_exists?)
          .with(hash_including(source_project_id: '123'))
          .and_return(false)

        manager.closed_merge_request_exists?(branch_name)
      end
    end

    context 'when HOUSEKEEPER_FORK_PROJECT_ID env var is not set' do
      before do
        stub_env('HOUSEKEEPER_FORK_PROJECT_ID', nil)
      end

      it 'defaults the source to the target project id' do
        expect(gitlab_client).to receive(:closed_merge_request_exists?)
          .with(hash_including(source_project_id: '456'))
          .and_return(false)

        manager.closed_merge_request_exists?(branch_name)
      end
    end
  end

  describe '#closed_merge_request_exists?' do
    it 'delegates to the client with the project scope' do
      expect(gitlab_client).to receive(:closed_merge_request_exists?)
        .with(project_scope)
        .and_return(true)

      expect(manager.closed_merge_request_exists?(branch_name)).to be(true)
    end
  end

  describe '#existing_merge_request' do
    it 'delegates to the client with the project scope' do
      merge_request = { 'web_url' => 'https://example.com' }

      expect(gitlab_client).to receive(:get_existing_merge_request)
        .with(project_scope)
        .and_return(merge_request)

      expect(manager.existing_merge_request(branch_name)).to eq(merge_request)
    end
  end

  describe '#create_or_update' do
    before do
      allow(gitlab_client).to receive(:non_housekeeper_changes).and_return([])
      allow(gitlab_client).to receive(:create_or_update_merge_request)
        .and_return({ 'web_url' => 'https://example.com' })
      allow(git).to receive(:push)
    end

    it 'sets non_housekeeper_changes and creates the MR' do
      expect(gitlab_client).to receive(:non_housekeeper_changes)
        .with(project_scope)
        .and_return([:title])
      expect(gitlab_client).to receive(:create_or_update_merge_request)
        .with(change: change, **project_scope)
        .and_return({ 'web_url' => 'https://example.com' })
      allow(keep).to receive(:should_push_code?).and_return(false)

      manager.create_or_update(change, branch_name, keep)

      expect(change.non_housekeeper_changes).to eq([:title])
    end

    it 'pushes when the keep says to push code' do
      allow(keep).to receive(:should_push_code?)
        .with(change, false, push_when_conflict: true)
        .and_return(true)

      expect(git).to receive(:push).with(branch_name, change.push_options)

      manager.create_or_update(change, branch_name, keep)
    end

    it 'does not push when the keep says not to push code' do
      allow(keep).to receive(:should_push_code?).and_return(false)

      expect(git).not_to receive(:push)

      manager.create_or_update(change, branch_name, keep)
    end
  end

  describe '#setup' do
    context 'when an existing merge request is found' do
      it 'sets mr attributes without creating' do
        allow(gitlab_client).to receive(:get_existing_merge_request)
          .and_return({ 'web_url' => 'https://example.com', 'has_conflicts' => true })

        expect(gitlab_client).not_to receive(:create_or_update_merge_request)

        manager.setup(change, branch_name, keep)

        expect(change.mr_web_url).to eq('https://example.com')
        expect(change.has_conflicts).to be(true)
      end
    end

    context 'when no existing merge request is found' do
      it 'creates the merge request and sets its attributes' do
        allow(gitlab_client).to receive(:get_existing_merge_request).and_return(nil)
        allow(gitlab_client).to receive(:non_housekeeper_changes).and_return([])
        allow(keep).to receive(:should_push_code?).and_return(false)
        allow(gitlab_client).to receive(:create_or_update_merge_request)
          .and_return({ 'web_url' => 'https://created.example.com' })

        manager.setup(change, branch_name, keep)

        expect(change.mr_web_url).to eq('https://created.example.com')
        expect(change.has_conflicts).to be(false)
      end
    end
  end
end
# rubocop:enable RSpec/MultipleMemoizedHelpers
