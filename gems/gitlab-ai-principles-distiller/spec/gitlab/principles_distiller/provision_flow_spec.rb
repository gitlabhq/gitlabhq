# frozen_string_literal: true

require 'spec_helper'
require_relative '../../support/tmpdir'
require_relative '../../../lib/gitlab/principles_distiller/provision_flow'

RSpec.describe Gitlab::PrinciplesDistiller::ProvisionFlow do
  include TmpdirHelper

  let(:tmpdir) { mktmpdir }
  let(:prompt_path) { File.join(tmpdir, '.ai/principles/distillation_prompt.md') }
  let(:prompt_content) { "<!-- author note -->\nYou are the agent.\nFollow the rules.\n" }
  let(:env) do
    {
      'GITLAB_TOKEN' => 'token-abc',
      'GITLAB_HOST' => nil,
      'AGENT_PRINCIPLES_CATALOG_PROJECT' => 'gitlab-org/gitlab',
      'AGENT_PRINCIPLES_CATALOG_FLOW_NAME' => nil
    }
  end

  before do
    stub_const('ENV', env_double(env))
    Gitlab::PrinciplesDistiller::Workspace.path = tmpdir
    FileUtils.mkdir_p(File.dirname(prompt_path))
    File.write(prompt_path, prompt_content)
  end

  describe '#load_distillation_prompt' do
    it 'strips the leading HTML comment' do
      result = described_class.new({ dry_run: true }).send(:load_distillation_prompt)

      expect(result).to eq("You are the agent.\nFollow the rules.")
      expect(result).not_to include('author note')
    end

    context 'when the prompt file is missing' do
      before do
        File.delete(prompt_path)
      end

      it 'aborts' do
        expect { described_class.new({ dry_run: true }).send(:load_distillation_prompt) }
          .to raise_error(SystemExit)
      end
    end
  end

  describe '#build_flow_yaml' do
    let(:instance) { described_class.new({ dry_run: true }) }

    it 'embeds the system prompt under prompt_template.system' do
      yaml = instance.send(:build_flow_yaml, "Line 1\nLine 2")
      parsed = YAML.safe_load(yaml)

      prompt = parsed.fetch('prompts').first.fetch('prompt_template')

      expect(prompt['system']).to include('Line 1', 'Line 2')
      expect(prompt['user']).to eq('{{goal}}')
      expect(prompt['placeholder']).to eq('history')
    end

    it 'sets environment to ambient (no-UI execution)' do
      parsed = YAML.safe_load(instance.send(:build_flow_yaml, 'x'))

      expect(parsed['environment']).to eq('ambient')
    end

    it 'wires the AgentComponent to the prompt and toolset', :aggregate_failures do
      parsed = YAML.safe_load(instance.send(:build_flow_yaml, 'x'))

      component = parsed.fetch('components').first

      expect(component['type']).to eq('AgentComponent')
      expect(component['prompt_id']).to eq('distiller_prompt')
      expect(component['toolset']).to match_array(described_class::TOOL_NAMES)
    end

    it 'declares only the goal input that the template references', :aggregate_failures do
      # The flow validator rejects declared inputs that the prompt
      # template does not reference. Only `goal` (used as {{goal}}) may be
      # declared; an unused `project` input made flow releases fail with
      # "extra input variables not present in template: ['project']".
      parsed = YAML.safe_load(instance.send(:build_flow_yaml, 'x'))

      component = parsed.fetch('components').first

      expect(component['inputs']).to eq([{ 'from' => 'context:goal', 'as' => 'goal' }])
    end

    it 'routes the single component to end' do
      parsed = YAML.safe_load(instance.send(:build_flow_yaml, 'x'))

      expect(parsed['routers']).to match_array([{ 'from' => 'distiller', 'to' => 'end' }])
      expect(parsed['flow']['entry_point']).to eq('distiller')
    end
  end

  describe 'TOOL_NAMES' do
    subject(:tool_names) { described_class::TOOL_NAMES }

    it { is_expected.to be_a(Array).and(be_any).and(all(be_a(String))) }

    it 'includes only read-only file-access tools' do
      expect(tool_names).to include('read_file', 'read_files', 'find_files', 'list_dir', 'grep')
    end

    it 'does NOT include any write or repository-modifying tools' do
      expect(tool_names).not_to include('edit_file', 'create_file_with_contents', 'create_commit',
        'run_command', 'create_merge_request')
    end
  end

  describe 'initialisation' do
    context 'when GITLAB_TOKEN is unset' do
      before do
        env['GITLAB_TOKEN'] = nil
      end

      it 'aborts' do
        expect { described_class.new({ dry_run: true }) }.to raise_error(SystemExit)
      end
    end

    context 'when AGENT_PRINCIPLES_CATALOG_PROJECT is unset' do
      before do
        env['AGENT_PRINCIPLES_CATALOG_PROJECT'] = nil
      end

      it 'aborts' do
        expect { described_class.new({ dry_run: true }) }.to raise_error(SystemExit)
      end
    end

    it 'reads project and flow name from env', :aggregate_failures do
      env['AGENT_PRINCIPLES_CATALOG_PROJECT'] = 'group/proj'
      env['AGENT_PRINCIPLES_CATALOG_FLOW_NAME'] = 'My Custom Flow'

      instance = described_class.new({ dry_run: true })

      expect(instance.instance_variable_get(:@project_path)).to eq('group/proj')
      expect(instance.instance_variable_get(:@flow_name)).to eq('My Custom Flow')
    end

    it 'falls back to DEFAULT_FLOW_NAME when AGENT_PRINCIPLES_CATALOG_FLOW_NAME is unset' do
      env['AGENT_PRINCIPLES_CATALOG_PROJECT'] = 'group/proj'

      instance = described_class.new({ dry_run: true })

      expect(instance.instance_variable_get(:@flow_name)).to eq(described_class::DEFAULT_FLOW_NAME)
    end
  end

  describe '.parse_options' do
    around do |example|
      original_argv = ARGV.dup
      example.run
    ensure
      ARGV.replace(original_argv)
    end

    it 'defaults dry_run to false' do
      ARGV.replace([])

      expect(described_class.parse_options).to eq(dry_run: false)
    end

    it 'sets dry_run when --dry-run is passed' do
      ARGV.replace(['--dry-run'])

      expect(described_class.parse_options).to eq(dry_run: true)
    end
  end

  # Returns a hash-like ENV double that responds to `[]`, `fetch`, and key checks
  # using the supplied hash. nil/empty values mimic an unset env var.
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
      alias_method :include?, :key?
      alias_method :has_key?, :key?

      def to_hash
        @env_hash.compact
      end
    end.new(env_hash)
  end
end
