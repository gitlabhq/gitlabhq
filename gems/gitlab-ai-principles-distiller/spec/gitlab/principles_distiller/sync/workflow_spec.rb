# frozen_string_literal: true

require 'spec_helper'
require_relative '../../../support/tmpdir'
require_relative '../../../../lib/gitlab/principles_distiller/sync'

RSpec.describe Gitlab::PrinciplesDistiller::Sync::Workflow do
  include TmpdirHelper

  # rubocop:disable RSpec/EnvAssignment -- ENV assignment is necessary in `around` blocks; stub_env requires `allow` which is not available outside `before`
  around do |example|
    original_branch = ENV['CI_DEFAULT_BRANCH']
    ENV['CI_DEFAULT_BRANCH'] ||= 'master'
    example.run
  ensure
    ENV['CI_DEFAULT_BRANCH'] = original_branch
  end
  # rubocop:enable RSpec/EnvAssignment

  let(:manifest) { Gitlab::PrinciplesDistiller::Sync::Manifest.new }
  let(:workflow) { described_class.new(manifest: manifest) }

  describe '.extract_assistant_content' do
    subject(:content) { workflow.extract_assistant_content(messages) }

    # DAP messages always have role: nil; we filter on messageType.
    context 'with a single agent message' do
      let(:messages) do
        [{ 'role' => nil, 'content' => "# Title\n\n## Checklist\n", 'messageType' => 'agent' }]
      end

      it { is_expected.to eq("# Title\n\n## Checklist\n") }
    end

    context 'with tool messages and an agent reply' do
      let(:messages) do
        [
          { 'role' => nil, 'content' => 'Starting Flow: ...', 'messageType' => 'tool' },
          { 'role' => nil, 'content' => 'Using read_files: ...', 'messageType' => 'tool' },
          { 'role' => nil, 'content' => "# Final\n\n## Checklist\n", 'messageType' => 'agent' }
        ]
      end

      it 'returns the agent message and skips tool messages' do
        expect(content).to eq("# Final\n\n## Checklist\n")
      end
    end

    context 'with multiple agent messages' do
      let(:messages) do
        [
          { 'role' => nil, 'content' => 'first reply', 'messageType' => 'agent' },
          { 'role' => nil, 'content' => 'second reply', 'messageType' => 'agent' }
        ]
      end

      it 'returns the last agent message' do
        expect(content).to eq('second reply')
      end
    end

    context 'with empty messages list' do
      let(:messages) { [] }

      it { is_expected.to be_nil }
    end

    context 'with nil messages' do
      let(:messages) { nil }

      it { is_expected.to be_nil }
    end

    context 'when the only agent message has empty content' do
      let(:messages) do
        [{ 'role' => nil, 'content' => '   ', 'messageType' => 'agent' }]
      end

      it { is_expected.to be_nil }
    end
  end

  describe '.log_failure_details' do
    subject(:log_failure) do
      workflow.log_failure_details(workflow_id, status, human_status, messages, ever_running)
    end

    let(:workflow_id) { 12345 }
    let(:status) { 'FAILED' }
    let(:human_status) { 'failed' }
    let(:ever_running) { true }

    before do
      allow(workflow).to receive(:catalog_project_path).and_return('gitlab-org/gitlab')
    end

    context 'with a normal message list' do
      let(:messages) do
        [
          { 'messageType' => 'tool', 'role' => nil, 'status' => 'completed', 'content' => 'Using read_files' },
          { 'messageType' => 'tool', 'role' => nil, 'status' => 'completed', 'content' => 'Using grep' }
        ]
      end

      it 'logs the workflow URL, human status, and message-type counts', :aggregate_failures do
        output = capture_stderr { log_failure }
        expect(output).to include('automate/agent-sessions/12345')
        expect(output).to include('humanStatus: "failed"')
        expect(output).to include('"tool"', '2')
        expect(output).to include('total 2')
      end
    end

    context 'with no messages' do
      let(:messages) { [] }

      it 'logs counts and total but no message previews', :aggregate_failures do
        output = capture_stderr { log_failure }
        expect(output).to include('total 0')
        expect(output).not_to include('content:')
      end
    end

    context 'with nil messages' do
      let(:messages) { nil }

      it 'treats it as empty and does not raise' do
        expect { log_failure }.not_to raise_error
      end
    end

    context 'with more than 5 messages' do
      let(:messages) do
        Array.new(8) { |i| { 'messageType' => 'tool', 'role' => nil, 'status' => 'ok', 'content' => "msg #{i}" } }
      end

      it 'previews only the last 5' do
        output = capture_stderr { log_failure }
        expect(output).to include('msg 7', 'msg 6', 'msg 5', 'msg 4', 'msg 3')
        expect(output).not_to include('msg 0', 'msg 1', 'msg 2')
      end
    end

    context 'with content longer than 500 chars' do
      let(:long) { 'x' * 800 }
      let(:messages) do
        [{ 'messageType' => 'agent', 'role' => nil, 'status' => 'ok', 'content' => long }]
      end

      it 'truncates the preview to 500 chars' do
        output = capture_stderr { log_failure }
        expect(output).to include('x' * 500)
        expect(output).not_to include('x' * 501)
      end
    end

    context 'when workflow never reached RUNNING and has no messages' do
      let(:ever_running) { false }
      let(:messages) { [] }

      it 'hints at Gitaly load as the likely cause', :aggregate_failures do
        output = capture_stderr { log_failure }
        expect(output).to include('never reached RUNNING')
        expect(output).to include('Gitaly')
        expect(output).to include('Known Limitations')
      end
    end

    def capture_stderr
      original = $stderr
      $stderr = StringIO.new
      yield
      $stderr.string
    ensure
      $stderr = original
    end
  end

  describe '.sleep_with_heartbeat' do
    it 'sleeps in 60s chunks and emits remaining-time heartbeats' do
      log_lines = []
      log = ->(msg) { log_lines << msg }

      allow(workflow).to receive(:sleep)

      workflow.sleep_with_heartbeat(130, 'retry 1 for security', log)

      expect(workflow).to have_received(:sleep).with(60).twice
      expect(workflow).to have_received(:sleep).with(10).once
      expect(log_lines).to include(a_string_including('retry 1 for security', '70s remaining'))
      expect(log_lines).to include(a_string_including('retry 1 for security', '10s remaining'))
    end

    it 'does not log when remaining hits 0 after the final chunk' do
      log_lines = []
      log = ->(msg) { log_lines << msg }
      allow(workflow).to receive(:sleep)

      workflow.sleep_with_heartbeat(60, 'retry 1 for security', log)

      expect(log_lines).to be_empty
    end
  end

  describe '.await_finished_content (private grace-period helper)' do
    # When a workflow flips to FINISHED, GraphQL's `latestCheckpoint.duoMessages`
    # can briefly lag the agent's final reply. The grace period polls a few
    # times before declaring the workflow content-less.
    subject(:result) { workflow.send(:await_finished_content, 'gid://gitlab/Workflow/1', 1) }

    before do
      allow(workflow).to receive(:sleep)
    end

    context 'when the agent message appears on the second grace poll' do
      let(:node_without_content) do
        { 'latestCheckpoint' => { 'duoMessages' => [
          { 'messageType' => 'tool', 'role' => nil, 'content' => 'Starting Flow:' }
        ] } }
      end

      let(:node_with_content) do
        { 'latestCheckpoint' => { 'duoMessages' => [
          { 'messageType' => 'tool', 'role' => nil, 'content' => 'Starting Flow:' },
          { 'messageType' => 'agent', 'role' => nil, 'content' => '# Distilled output' }
        ] } }
      end

      before do
        allow(workflow).to receive(:fetch_workflow_node)
          .and_return(node_without_content, node_with_content)
      end

      it 'returns the content once it appears' do
        expect(result).to eq('# Distilled output')
      end
    end

    context 'when the agent message never appears within the grace window' do
      let(:node_without_content) do
        { 'latestCheckpoint' => { 'duoMessages' => [
          { 'messageType' => 'tool', 'role' => nil, 'content' => 'Using read_files:' }
        ] } }
      end

      before do
        allow(workflow).to receive(:fetch_workflow_node).and_return(node_without_content)
      end

      it 'returns nil after exhausting the grace polls' do
        expect(result).to be_nil
      end

      it 'sleeps once per grace poll' do
        result
        expect(workflow).to have_received(:sleep).exactly(described_class::FINISHED_CONTENT_GRACE_POLLS).times
      end
    end

    context 'when the workflow node disappears mid-grace (transient lookup failure)' do
      before do
        allow(workflow).to receive(:fetch_workflow_node).and_return(nil)
      end

      it 'keeps polling rather than crashing' do
        expect { result }.not_to raise_error
        expect(result).to be_nil
      end
    end
  end

  describe '.build_goal' do
    subject(:goal) { workflow.build_goal('feature-flags', config) }

    let(:config) do
      {
        'sources' => [
          { 'path' => 'doc/development/feature_flags/_index.md' },
          { 'path' => 'doc/development/feature_flags/usage.md' }
        ],
        'baseline' => '.ai/principles/baselines/feature-flags.md'
      }
    end

    it 'lists the principle name in the prompt' do
      expect(goal).to include('"feature-flags"')
    end

    it 'lists the SSOT source paths', :aggregate_failures do
      expect(goal).to include('- doc/development/feature_flags/_index.md')
      expect(goal).to include('- doc/development/feature_flags/usage.md')
    end

    it 'lists the baseline path' do
      expect(goal).to include('- .ai/principles/baselines/feature-flags.md')
    end

    it 'mentions the distilled file path' do
      expect(goal).to include('.ai/principles/distilled/feature-flags.md')
    end

    context 'without a baseline' do
      let(:config) { { 'sources' => [{ 'path' => 'doc/foo.md' }] } }

      it 'reports baseline as (none)' do
        expect(goal).to include('(none)')
      end
    end
  end

  describe '.build_additional_context' do
    subject(:context) { workflow.build_additional_context('foo', config) }

    let(:config) do
      {
        'sources' => [{ 'path' => 'doc/foo.md', 'url' => 'https://example.com/foo' }],
        'baseline' => '.ai/principles/baselines/foo.md'
      }
    end

    it 'returns a one-element array' do
      expect(context.size).to eq(1)
    end

    it 'uses agent_principles_distillation as Category' do
      expect(context[0][:Category]).to eq('agent_principles_distillation')
    end

    it 'serialises the principle metadata as Content JSON', :aggregate_failures do
      payload = JSON.parse(context[0][:Content]) # -- fast_spec_helper has no Gitlab::Json

      expect(payload['principle']).to eq('foo')
      expect(payload['distilled_path']).to eq('.ai/principles/distilled/foo.md')
      expect(payload['sources']).to eq([{ 'path' => 'doc/foo.md', 'url' => 'https://example.com/foo' }])
      expect(payload['baseline_path']).to eq('.ai/principles/baselines/foo.md')
    end
  end

  describe '.validate_sources!' do
    subject(:validate) { workflow.validate_sources!(config) }

    let(:tmpdir) { mktmpdir }

    before do
      Gitlab::PrinciplesDistiller::Workspace.path = tmpdir
      FileUtils.mkdir_p(File.join(tmpdir, 'doc'))
      FileUtils.mkdir_p(File.join(tmpdir, '.ai', 'principles', 'baselines'))
      File.write(File.join(tmpdir, 'doc', 'present.md'), 'content')
    end

    context 'when every source path and the baseline exist' do
      let(:config) do
        {
          'sources' => [{ 'path' => 'doc/present.md' }],
          'baseline' => '.ai/principles/baselines/present.md'
        }
      end

      before do
        File.write(File.join(tmpdir, '.ai', 'principles', 'baselines', 'present.md'), 'content')
      end

      it 'does not raise' do
        expect { validate }.not_to raise_error
      end
    end

    context 'when a source path is missing' do
      let(:config) { { 'sources' => [{ 'path' => 'doc/missing.md' }] } }

      it 'raises naming the missing source path' do
        expect { validate }.to raise_error(%r{SSOT source file not found: doc/missing\.md})
      end
    end

    context 'when the baseline path is missing' do
      let(:config) do
        {
          'sources' => [{ 'path' => 'doc/present.md' }],
          'baseline' => '.ai/principles/baselines/missing.md'
        }
      end

      it 'raises naming the missing baseline path' do
        expect { validate }
          .to raise_error(%r{SSOT source file not found: \.ai/principles/baselines/missing\.md})
      end
    end
  end

  describe '.validate_config!' do
    subject(:validate) { workflow.validate_config! }

    context 'when both env vars are set' do
      before do
        stub_const('ENV',
          env_double('GITLAB_TOKEN' => 'token', 'AGENT_PRINCIPLES_CATALOG_ITEM_CONSUMER_ID' => '123'))
      end

      it 'does not abort' do
        expect { validate }.not_to raise_error
      end
    end

    context 'when GITLAB_TOKEN is missing' do
      before do
        stub_const('ENV',
          env_double('GITLAB_TOKEN' => '', 'AGENT_PRINCIPLES_CATALOG_ITEM_CONSUMER_ID' => '123'))
      end

      it 'aborts' do
        expect { validate }.to raise_error(SystemExit)
      end
    end

    context 'when AGENT_PRINCIPLES_CATALOG_ITEM_CONSUMER_ID is missing' do
      before do
        stub_const('ENV',
          env_double('GITLAB_TOKEN' => 'token', 'AGENT_PRINCIPLES_CATALOG_ITEM_CONSUMER_ID' => ''))
      end

      it 'aborts' do
        expect { validate }.to raise_error(SystemExit)
      end
    end

    # Hash-like ENV double for tests. Returns nil for unset keys via [];
    # fetch returns the default when the value is empty/nil/missing.
    def env_double(env_hash)
      Class.new do
        def initialize(env_hash)
          @env_hash = env_hash
        end

        def [](key)
          @env_hash[key]
        end

        def fetch(key, *args, &blk)
          value = @env_hash[key]
          return value if value && !value.to_s.empty?
          return args.first if args.any?
          return yield(key) if blk

          raise KeyError, key
        end

        def key?(key)
          @env_hash.key?(key) && !@env_hash[key].to_s.empty?
        end
      end.new(env_hash)
    end
  end
end
