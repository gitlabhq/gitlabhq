# frozen_string_literal: true

require 'spec_helper'
require_relative '../../../../lib/gitlab/principles_distiller/sync'

RSpec.describe Gitlab::PrinciplesDistiller::Sync::CLI do
  subject(:run) { described_class.run(arguments) }

  let(:arguments) { [] }
  let(:sync) { instance_double(Gitlab::PrinciplesDistiller::Sync) }

  before do
    allow(Gitlab::PrinciplesDistiller::Sync).to receive(:new).and_return(sync)
    allow(sync).to receive(:distill_and_publish)
    allow(sync).to receive(:generate_child_pipeline)
    allow(sync).to receive(:distill_one)
    allow(sync).to receive(:collect)
    allow(sync).to receive(:check_duo_instructions_fences)
    allow(sync).to receive(:reconcile_duo_instructions_fences)
  end

  [
    ['distill --push --force --only qa,backend --dry-run --rewrite'.split, :distill_and_publish,
      [{ push: true, force: true, only: %w[qa backend], dry_run: true, rewrite: true }]],
    ['generate-pipeline --force --only qa'.split, :generate_child_pipeline, [{ force: true, only: ['qa'] }]],
    [%w[distill-one qa], :distill_one, ['qa']],
    ['collect qa,backend --push'.split, :collect, [%w[qa backend], { push: true }]],
    # The generated child pipeline passes an empty expected list when no principles need distillation.
    [['collect', '', '--push'], :collect, [[], { push: true }]],
    ['check-fences --warn-stale'.split, :check_duo_instructions_fences, [{ warn_stale: true }]],
    ['reconcile-fences --push'.split, :reconcile_duo_instructions_fences, [{ push: true }]]
  ].each do |command_arguments, method, arguments_to_method|
    it 'dispatches the subcommand' do
      described_class.run(command_arguments)

      expect(sync).to have_received(method).with(*arguments_to_method)
    end
  end

  it 'accepts --workspace before the subcommand' do
    described_class.run(%w[--workspace /tmp distill])

    expect(Gitlab::PrinciplesDistiller::Workspace.path).to eq('/tmp')
  end

  it 'accepts --workspace after the subcommand' do
    described_class.run(%w[distill --workspace /tmp])

    expect(Gitlab::PrinciplesDistiller::Workspace.path).to eq('/tmp')
  end

  [
    [%w[check-fences --push], 'check-fences'],
    [%w[distill-one qa --force], 'distill-one'],
    [%w[generate-pipeline --dry-run], 'generate-pipeline']
  ].each do |invalid_arguments, command_name|
    it 'rejects an option not accepted by the subcommand' do
      expect { described_class.run(invalid_arguments) }
        .to raise_error(SystemExit)
        .and output(/unknown option .* for '#{command_name}'/).to_stderr
    end
  end

  it 'rejects an unknown subcommand' do
    expect { described_class.run(['unknown']) }
      .to raise_error(SystemExit)
      .and output(/unknown subcommand 'unknown'/).to_stderr
  end

  it 'rejects a missing subcommand' do
    expect { run }
      .to raise_error(SystemExit)
      .and output(/missing subcommand/).to_stderr
  end

  it 'shows all subcommands in global help' do
    expect { described_class.run(['--help']) }
      .to raise_error(SystemExit)
      .and output(/distill.*generate-pipeline.*distill-one.*collect.*check-fences.*reconcile-fences/m).to_stdout
  end

  it 'shows only the selected subcommand options in command help' do
    expect { described_class.run(%w[distill --help]) }
      .to raise_error(SystemExit)
      .and output(/\A(?!.*--warn-stale).*--dry-run.*--push.*--force.*--only.*--rewrite/m).to_stdout
  end

  it 'rejects missing positional arguments' do
    expect { described_class.run(['collect']) }
      .to raise_error(SystemExit)
      .and output(/Usage: gitlab-ai-principles-distiller-sync collect/).to_stderr
  end

  it 'rejects an empty distill-one name' do
    expect { described_class.run(['distill-one', '']) }
      .to raise_error(SystemExit)
      .and output(/Usage: gitlab-ai-principles-distiller-sync distill-one/).to_stderr
  end
end
