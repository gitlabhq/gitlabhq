# frozen_string_literal: true

require 'spec_helper'
require_relative '../../support/tmpdir'
require_relative '../../../lib/gitlab/principles_distiller/flow_definition'

RSpec.describe Gitlab::PrinciplesDistiller::FlowDefinition do
  include TmpdirHelper

  let(:tmpdir) { mktmpdir }
  let(:prompt_path) { File.join(tmpdir, described_class::PROMPT_PATH) }

  def write_prompt(content)
    FileUtils.mkdir_p(File.dirname(prompt_path))
    File.write(prompt_path, content)
  end

  before do
    Gitlab::PrinciplesDistiller::Workspace.path = tmpdir
  end

  describe '.load_distillation_prompt' do
    it 'strips the leading authoring-instructions HTML comment' do
      write_prompt("<!--\n  Editing rules: do not ship this.\n-->\nYou are the distiller.\n")

      expect(described_class.load_distillation_prompt).to eq('You are the distiller.')
    end

    it 'keeps an HTML comment that is not the leading block' do
      write_prompt("You are the distiller.\n\n<!-- keep me -->\n")

      expect(described_class.load_distillation_prompt).to include('<!-- keep me -->')
    end

    it 'aborts when the prompt is missing' do
      expect { described_class.load_distillation_prompt }
        .to raise_error(SystemExit)
        .and output(/prompt not found/).to_stderr
    end
  end

  describe '.stored_definition_bytesize' do
    let(:yaml_definition) { described_class.build_flow_yaml('You are the distiller.') }

    it 'counts the prompt twice, because the catalog also stores the raw YAML' do
      # The stored definition holds the parsed structure AND `yaml_definition`, so it must exceed the YAML itself.
      expect(described_class.stored_definition_bytesize(yaml_definition))
        .to be > (yaml_definition.bytesize * 1.5)
    end

    it 'escapes the characters Oj escapes in Rails mode' do
      # Each `<`, `>`, and `&` becomes a 6-byte `\uXXXX` escape, so +5 bytes apiece.
      # The string holds 5 of them (two `<`, two `>`, one `&`), and the prompt is stored twice: 5 * 5 * 2.
      escaped = described_class.build_flow_yaml('Compare <a> & <b>.')
      plain = described_class.build_flow_yaml('Compare .a. . .b..')

      expect(described_class.stored_definition_bytesize(escaped))
        .to eq(described_class.stored_definition_bytesize(plain) + (5 * 5 * 2))
    end
  end

  describe '.within_size_limit?' do
    it 'is true for a short prompt' do
      expect(described_class.within_size_limit?(described_class.build_flow_yaml('Short.'))).to be(true)
    end

    it 'is false once the stored definition exceeds the limit' do
      # ~40 KiB of prompt is under the limit as YAML but over it once stored twice.
      oversized = described_class.build_flow_yaml('word ' * 8_000)

      expect(oversized.bytesize).to be < described_class::DEFINITION_SIZE_LIMIT
      expect(described_class.within_size_limit?(oversized)).to be(false)
    end
  end

  describe '.size_report' do
    it 'reports stored bytes, the limit, the remaining headroom, and the YAML size' do
      yaml_definition = described_class.build_flow_yaml('Short.')
      stored = described_class.stored_definition_bytesize(yaml_definition)

      expect(described_class.size_report(yaml_definition)).to eq(
        "stored definition #{stored} bytes / #{described_class::DEFINITION_SIZE_LIMIT} limit " \
          "(+#{described_class::DEFINITION_SIZE_LIMIT - stored}, YAML #{yaml_definition.bytesize} bytes)"
      )
    end
  end

  describe '.build_flow_yaml' do
    let(:parsed) { YAML.safe_load(described_class.build_flow_yaml("Line one.\n\nLine two.")) }

    it 'produces a definition the AI Catalog flow schema accepts' do
      expect(parsed).to include('version' => 'v1', 'environment' => 'ambient')
      expect(parsed.dig('flow', 'entry_point')).to eq('distiller')
    end

    it 'carries the prompt through the block scalar without losing blank lines' do
      expect(parsed.dig('prompts', 0, 'prompt_template', 'system')).to eq("Line one.\n\nLine two.\n")
    end

    it 'grants the agent only read-only tools' do
      expect(parsed.dig('components', 0, 'toolset')).to eq(described_class::TOOL_NAMES)
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

  describe 'the committed prompt' do
    # Regression guard for https://gitlab.com/gitlab-org/gitlab/-/issues/608440:
    # https://gitlab.com/gitlab-org/gitlab/-/merge_requests/248765 pushed the stored definition to
    # 65,811 bytes (275 over) while its YAML was only ~33 KiB, so the flow could not be published.
    let(:repo_root) { File.expand_path('../../../../..', __dir__) }
    let(:yaml_definition) do
      Gitlab::PrinciplesDistiller::Workspace.path = repo_root

      described_class.build_flow_yaml(described_class.load_distillation_prompt)
    end

    it 'fits the catalog budget' do
      expect(described_class.within_size_limit?(yaml_definition)).to be(true),
        -> { "prompt is over budget: #{described_class.size_report(yaml_definition)}" }
    end

    it 'keeps enough headroom to absorb a routine prompt addition' do
      # !248765 added ~500 bytes of Markdown, which cost ~1,100 stored bytes.
      headroom = described_class::DEFINITION_SIZE_LIMIT -
        described_class.stored_definition_bytesize(yaml_definition)

      expect(headroom).to be > 2_000
    end
  end
end
