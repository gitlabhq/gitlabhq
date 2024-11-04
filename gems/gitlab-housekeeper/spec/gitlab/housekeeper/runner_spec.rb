# frozen_string_literal: true

require 'spec_helper'
require 'gitlab/housekeeper/runner'
require 'rspec/parameterized'

# rubocop:disable RSpec/MultipleMemoizedHelpers -- there are lots of parameters at play
RSpec.describe ::Gitlab::Housekeeper::Runner do
  let(:fake_keep) { instance_double(Class) }

  let(:change1) do
    create_change(
      identifiers: %w[the identifier for the first change],
      title: "The title of MR1"
    )
  end

  let(:change2) do
    create_change(
      identifiers: %w[the identifier for the second change],
      title: "The title of MR2"
    )
  end

  let(:change3) do
    create_change(
      identifiers: %w[the identifier for the third change],
      title: "The title of MR3"
    )
  end

  before do
    fake_keep_instance = instance_double(::Gitlab::Housekeeper::Keep)
    allow(fake_keep).to receive(:new).and_return(fake_keep_instance)

    allow(fake_keep_instance).to receive(:each_change)
      .and_yield(change1)
      .and_yield(change2)
      .and_yield(change3)
  end

  describe '#run' do
    let(:git) { instance_double(::Gitlab::Housekeeper::Git) }
    let(:gitlab_client) { instance_double(::Gitlab::Housekeeper::GitlabClient) }
    let(:substitutor) { instance_double(::Gitlab::Housekeeper::Substitutor) }

    before do
      stub_env('HOUSEKEEPER_FORK_PROJECT_ID', '123')
      stub_env('HOUSEKEEPER_TARGET_PROJECT_ID', '456')

      allow(::Gitlab::Housekeeper::Git).to receive(:new)
        .and_return(git)
      allow(git).to receive(:with_clean_state)
        .and_yield

      allow(git).to receive(:create_branch).with(change1)
        .and_return('the-identifier-for-the-first-change')
      allow(git).to receive(:in_branch).with('the-identifier-for-the-first-change')
        .and_yield
      allow(git).to receive(:create_commit).with(change1)

      allow(git).to receive(:create_branch).with(change2)
        .and_return('the-identifier-for-the-second-change')
      allow(git).to receive(:in_branch).with('the-identifier-for-the-second-change')
        .and_yield
      allow(git).to receive(:create_commit).with(change2)
      allow(git).to receive(:push)

      allow(::Gitlab::Housekeeper::GitlabClient).to receive(:new)
        .and_return(gitlab_client)

      allow(gitlab_client).to receive(:get_existing_merge_request)
        .and_return(nil)

      allow(gitlab_client).to receive(:non_housekeeper_changes)
        .and_return([])

      allow(::Gitlab::Housekeeper::Shell).to receive(:execute)
    end

    it 'loops over the keeps and creates MRs limited by max_mrs' do
      # Branches get created
      expect(git).to receive(:create_branch).with(change1)
        .and_return('the-identifier-for-the-first-change')
      expect(git).to receive(:create_commit).with(change1)

      expect(git).to receive(:create_branch).with(change2)
        .and_return('the-identifier-for-the-second-change')
      expect(git).to receive(:create_commit).with(change2)

      expect(::Gitlab::Housekeeper::Substitutor).to receive(:perform).with(change1)
      expect(::Gitlab::Housekeeper::Substitutor).to receive(:perform).with(change2)

      # Branches get shown and pushed
      expect(::Gitlab::Housekeeper::Shell).to receive(:execute)
        .with('git', '--no-pager', 'diff', '--color=always', 'master',
          'the-identifier-for-the-first-change', '--', 'change1.txt', 'change2.txt')
      expect(git).to receive(:push)
        .with('the-identifier-for-the-first-change', change1.push_options)
      expect(::Gitlab::Housekeeper::Shell).to receive(:execute)
        .with('git', '--no-pager', 'diff', '--color=always', 'master',
          'the-identifier-for-the-second-change', '--', 'change1.txt', 'change2.txt')
      expect(git).to receive(:push)
        .with('the-identifier-for-the-second-change', change2.push_options)

      # Merge requests get created
      expect(gitlab_client).to receive(:create_or_update_merge_request)
        .with(
          change: change1,
          source_project_id: '123',
          source_branch: 'the-identifier-for-the-first-change',
          target_branch: 'master',
          target_project_id: '456'
        ).twice.and_return({ 'web_url' => 'https://example.com' })
      expect(gitlab_client).to receive(:create_or_update_merge_request)
        .with(
          change: change2,
          source_project_id: '123',
          source_branch: 'the-identifier-for-the-second-change',
          target_branch: 'master',
          target_project_id: '456'
        ).twice.and_return({ 'web_url' => 'https://example.com' })

      described_class.new(max_mrs: 2, keeps: [fake_keep]).run

      # It sets the keep_class for the change
      expect(change1.keep_class).to eq(fake_keep)
      expect(change2.keep_class).to eq(fake_keep)
    end

    context 'when given target_branch' do
      it 'branches from that target branch' do
        # Branches get created
        expect(::Gitlab::Housekeeper::Git).to receive(:new)
          .with(logger: anything, branch_from: 'the-target-branch')
          .and_return(git)

        # Branches get shown and pushed
        expect(::Gitlab::Housekeeper::Shell).to receive(:execute)
          .with('git', '--no-pager', 'diff', '--color=always', 'the-target-branch',
            'the-identifier-for-the-first-change', '--', 'change1.txt', 'change2.txt')

        # Merge requests get created
        expect(gitlab_client).to receive(:create_or_update_merge_request)
          .with(
            change: change1,
            source_project_id: '123',
            source_branch: 'the-identifier-for-the-first-change',
            target_branch: 'the-target-branch',
            target_project_id: '456'
          ).twice.and_return({ 'web_url' => 'https://example.com' })

        described_class.new(max_mrs: 1, keeps: [fake_keep], target_branch: 'the-target-branch').run
      end
    end

    context 'when given filter_identifiers' do
      it 'skips a change that does not match the filter_identifiers' do
        # Branches get created
        expect(git).to receive(:create_branch).with(change1)
          .and_return('the-identifier-for-the-first-change')
        allow(git).to receive(:in_branch).with('the-identifier-for-the-first-change')
          .and_yield
        expect(git).to receive(:create_commit).with(change1)

        expect(git).to receive(:create_branch).with(change2)
          .and_return('the-identifier-for-the-second-change')
        allow(git).to receive(:in_branch).with('the-identifier-for-the-second-change')
          .and_yield
        expect(git).to receive(:create_commit).with(change2)

        expect(git).to receive(:create_branch).with(change3)
          .and_return('the-identifier-for-the-third-change')
        allow(git).to receive(:in_branch).with('the-identifier-for-the-third-change')
          .and_yield
        expect(git).to receive(:create_commit).with(change3)

        expect(::Gitlab::Housekeeper::Substitutor).to receive(:perform).with(change2)

        # Branches get shown and pushed
        expect(::Gitlab::Housekeeper::Shell).to receive(:execute)
          .with('git', '--no-pager', 'diff', '--color=always', 'master',
            'the-identifier-for-the-second-change', '--', 'change1.txt', 'change2.txt')
        expect(git).to receive(:push)
          .with('the-identifier-for-the-second-change', change2.push_options)

        # Merge requests get created
        expect(gitlab_client).to receive(:create_or_update_merge_request)
          .with(
            change: change2,
            source_project_id: '123',
            source_branch: 'the-identifier-for-the-second-change',
            target_branch: 'master',
            target_project_id: '456'
          ).twice.and_return({ 'web_url' => 'https://example.com' })

        described_class.new(max_mrs: 2, keeps: [fake_keep], filter_identifiers: [/second/]).run
      end
    end

    context 'on dry run' do
      context 'for completion message' do
        it 'prints the expected message' do
          expect do
            described_class.new(max_mrs: 1, keeps: [fake_keep], dry_run: true).run
          end.to output(/Dry run complete. Housekeeper would have created 1 MR on an actual run./).to_stdout
        end
      end
    end
  end

  describe '#housekeeper_fork_project_id' do
    before do
      stub_env('HOUSEKEEPER_FORK_PROJECT_ID', nil)
      stub_env('HOUSEKEEPER_TARGET_PROJECT_ID', '456')
    end

    context 'when HOUSEKEEPER_FORK_PROJECT_ID env var is set' do
      before do
        stub_env('HOUSEKEEPER_FORK_PROJECT_ID', '123')
      end

      it 'gets its value from the env var' do
        expect(described_class.new.housekeeper_fork_project_id).to eq('123')
      end
    end

    it 'defaults to HOUSEKEEPER_TARGET_PROJECT_ID env var' do
      expect(described_class.new.housekeeper_fork_project_id).to eq('456')
    end
  end

  describe '.should_push_code?' do
    using RSpec::Parameterized::TableSyntax

    # rubocop:disable Lint/BinaryOperatorWithIdenticalOperands -- false positive rspec table syntax not binary operator
    where(:already_approved, :push_when_approved, :code_update_required, :expected_result) do
      true  | false | true  | false
      true  | false | false | false
      true  | true  | true  | true
      true  | true  | false | false
      false | true  | true  | true
      false | true  | false | false
    end
    # rubocop:enable Lint/BinaryOperatorWithIdenticalOperands

    with_them do
      it "determines if we should push" do
        change = instance_double(::Gitlab::Housekeeper::Change)

        allow(change).to receive(:already_approved?).and_return(already_approved)
        allow(change).to receive(:update_required?).with(:code).and_return(code_update_required)

        result = described_class.should_push_code?(change, push_when_approved)
        expect(result).to eq(expected_result)
      end
    end
  end
end
# rubocop:enable RSpec/MultipleMemoizedHelpers
