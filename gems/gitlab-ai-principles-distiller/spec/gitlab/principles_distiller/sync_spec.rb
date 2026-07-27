# frozen_string_literal: true

require 'spec_helper'
require_relative '../../support/tmpdir'
require_relative '../../../lib/gitlab/principles_distiller/sync'

RSpec.describe Gitlab::PrinciplesDistiller::Sync do
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

  let(:tmpdir) { mktmpdir }
  let(:sync) { described_class.new }

  describe '.distill_and_write_principles' do
    let(:principles_dir) { File.join(tmpdir, '.ai/principles/distilled') }
    let(:manifest) do
      {
        'principles' => {
          'qa' => {
            'sources' => [
              { 'path' => 'doc/development/testing_guide/best_practices.md' }
            ]
          }
        }
      }
    end

    let(:affected) do
      { 'qa' => { config: manifest.dig('principles', 'qa'), changed_sources: [] } }
    end

    let(:existing_content) { "# QA Principles\n\n## Checklist\n\n### Test Coverage\n\n- Old rule\n" }
    let(:distilled_content) { "# QA Principles\n\n## Checklist\n\n### Test Coverage\n\n- New code has tests\n" }

    before do
      Gitlab::PrinciplesDistiller::Workspace.path = tmpdir
      stub_const("#{described_class}::Manifest::PRINCIPLES_DIR", '.ai/principles/distilled')
      FileUtils.mkdir_p(principles_dir)
      sync.manifest.data = manifest

      allow(sync).to receive(:parallel_distill)
        .and_return({ 'qa' => [existing_content, distilled_content] })
    end

    it 'writes the file with frontmatter, header, content, and sources footer', :aggregate_failures do
      sync.distill_and_write_principles(affected)

      written = File.read(File.join(principles_dir, 'qa.md'))

      expect(written).to start_with("---\nsource_checksum:")
      expect(written).to include('<!-- Auto-generated from docs.gitlab.com')
      expect(written).to include('### Test Coverage')
      expect(written).to include('## Authoritative sources')
      expect(written).to include('- doc/development/testing_guide/best_practices.md')
    end

    it 'returns updated principles and no failures', :aggregate_failures do
      updated, failed = sync.distill_and_write_principles(affected)

      expect(updated.keys).to eq(['qa'])
      expect(failed).to be_empty
    end

    context 'when distillation fails' do
      before do
        allow(sync).to receive(:parallel_distill)
          .and_return({ 'qa' => [nil, nil] })
      end

      it 'reports failure', :aggregate_failures do
        updated, failed = sync.distill_and_write_principles(affected)

        expect(updated).to be_empty
        expect(failed).to eq(['qa'])
      end
    end

    # Regression: a re-distillation that produces the same checklist must be
    # skipped, not emitted as a frontmatter-only MR (new source_checksum /
    # distilled_at_sha but an identical body). In production `current` is read
    # from disk WITH the auto-generated header and authoritative sources footer
    # intact (strip_frontmatter removes only the YAML block), while `updated`
    # is the raw LLM checklist WITHOUT that footer. The meaningful? gate must
    # therefore compare the fully-assembled body against `current`; hence
    # `existing_on_disk` includes the footer to mirror real on-disk content.
    context 'when content has no meaningful diff from existing file' do
      let(:header) do
        "<!-- Auto-generated from docs.gitlab.com by " \
          "gitlab-ai-principles-distiller — do not edit manually -->\n\n"
      end

      let(:footer) do
        config = manifest.dig('principles', 'qa')
        sync.manifest.sources_footer(config)
      end

      let(:existing_on_disk) do
        "#{header}#{distilled_content.rstrip}\n\n#{footer}"
      end

      before do
        allow(sync).to receive(:parallel_distill)
          .and_return({ 'qa' => [existing_on_disk, distilled_content] })
      end

      it 'skips the file', :aggregate_failures do
        updated, failed = sync.distill_and_write_principles(affected)

        expect(updated).to be_empty
        expect(failed).to be_empty
      end
    end

    context 'when the distilled file does not exist yet (current is nil)' do
      before do
        allow(sync).to receive(:parallel_distill)
          .and_return({ 'qa' => [nil, distilled_content] })
      end

      it 'writes the new file' do
        sync.distill_and_write_principles(affected)

        expect(File.exist?(File.join(principles_dir, 'qa.md'))).to be true
      end

      it 'returns the new principle as updated and reports no failures', :aggregate_failures do
        updated, failed = sync.distill_and_write_principles(affected)

        expect(updated.keys).to eq(['qa'])
        expect(failed).to be_empty
      end
    end
  end

  describe '.announce_distillation_start' do
    before do
      Gitlab::PrinciplesDistiller::Workspace.path = tmpdir
      stub_const("#{described_class}::Manifest::PRINCIPLES_DIR", '.ai/principles/distilled')
    end

    context 'when the distilled file exists' do
      before do
        FileUtils.mkdir_p(File.join(tmpdir, '.ai/principles/distilled'))
        File.write(File.join(tmpdir, '.ai/principles/distilled/qa-rspec.md'),
          "---\nsource_checksum: abc\n---\n# QA RSpec Principles\n\n## Checklist\n")
      end

      it 'logs that distillation will refresh the existing file' do
        expect { sync.announce_distillation_start('qa-rspec', nil) }
          .to output(/distilling \(existing file found\)/).to_stdout
      end
    end

    context 'when the distilled file does not exist' do
      it 'logs that distillation will regenerate from scratch' do
        expect { sync.announce_distillation_start('qa-rspec', nil) }
          .to output(/no existing file/).to_stdout
      end
    end
  end

  describe '.distill_principle (retry loop)' do
    # `distill_principle` is private (it's an internal step of
    # parallel_distill), so specs reach it via `send`. The retry loop is
    # the most failure-prone control flow in the gem: any of the three
    # Duo invocations can return nil, return content missing the
    # required heading, or succeed.
    subject(:distill) { sync.send(:distill_principle, 'qa', config) }

    let(:config) { { 'sources' => [{ 'path' => 'doc/qa.md' }] } }
    let(:valid_content) { "# QA Principles\n\n## Checklist\n\n- Do thing\n" }

    before do
      Gitlab::PrinciplesDistiller::Workspace.path = tmpdir
      FileUtils.mkdir_p(File.join(tmpdir, 'doc'))
      File.write(File.join(tmpdir, 'doc/qa.md'), 'source content')

      # Bypass real waits between retries. We assert the call site
      # separately rather than letting the test stall for 5+ minutes.
      allow(sync.workflow).to receive(:sleep_with_heartbeat)
      allow(sync.workflow).to receive(:validate_sources!)
    end

    context 'when the first attempt returns valid content' do
      before do
        allow(sync.workflow).to receive(:distill).and_return(valid_content)
      end

      it 'returns the stripped content without retrying' do
        expect(distill).to include('## Checklist')
        expect(sync.workflow).to have_received(:distill).once
        expect(sync.workflow).not_to have_received(:sleep_with_heartbeat)
      end
    end

    context 'when the first attempt returns nil and the second succeeds' do
      before do
        allow(sync.workflow).to receive(:distill).and_return(nil, valid_content)
      end

      it 'retries and returns the second result' do
        expect(distill).to include('## Checklist')
        expect(sync.workflow).to have_received(:distill).twice
        expect(sync.workflow).to have_received(:sleep_with_heartbeat)
          .with(described_class::DISTILL_RETRY_BACKOFF_SECONDS[0], anything, anything)
          .once
      end
    end

    context 'when the first attempt returns content without the Checklist heading' do
      let(:invalid_content) { "# QA Principles\n\nSome other content\n" }

      before do
        allow(sync.workflow).to receive(:distill).and_return(invalid_content, valid_content)
      end

      it 'treats the missing heading as failure and retries' do
        expect(distill).to include('## Checklist')
        expect(sync.workflow).to have_received(:distill).twice
      end
    end

    context 'when all attempts return nil' do
      before do
        allow(sync.workflow).to receive(:distill).and_return(nil)
      end

      it 'returns nil after DISTILL_MAX_RETRIES attempts' do
        expect { distill }.to output(/Duo failed after #{described_class::DISTILL_MAX_RETRIES} attempts/o).to_stderr
        expect(distill).to be_nil
        expect(sync.workflow).to have_received(:distill)
          .exactly(described_class::DISTILL_MAX_RETRIES).times
      end

      it 'sleeps with the configured backoff schedule between retries' do
        distill

        described_class::DISTILL_RETRY_BACKOFF_SECONDS
          .first(described_class::DISTILL_MAX_RETRIES - 1)
          .each do |backoff|
            expect(sync.workflow).to have_received(:sleep_with_heartbeat)
              .with(backoff, anything, anything)
          end
      end
    end

    context 'when content is returned but lacks Checklist on every attempt' do
      let(:invalid_content) { '# Bad header without checklist' }

      before do
        allow(sync.workflow).to receive(:distill).and_return(invalid_content)
      end

      it 'logs a preview of each failed response and returns nil' do
        expect { distill }.to output(/Response preview/).to_stderr
        expect(distill).to be_nil
      end
    end

    # Mechanical guard for prompt rule 15: baseline rules must appear
    # verbatim, exactly once. A re-distillation once relocated AND corrupted
    # a baseline section (duplicated sentence fragment, broken sub-bullet)
    # despite the verbatim instruction; prompt-only enforcement is not
    # enough, so baseline drift must consume a retry instead of publishing.
    # The check compares normalized logical units (bullets/paragraphs with
    # wrapping and whitespace collapsed), not physical lines: the agent
    # routinely re-flows hard-wrapped lines, and identical text with
    # different wrapping is not corruption.
    context 'when the principle has a baseline' do
      let(:config) do
        {
          'sources' => [{ 'path' => 'doc/qa.md' }],
          'baseline' => '.ai/principles/baselines/qa.md'
        }
      end

      let(:baseline_content) do
        <<~BASELINE
          ### Process Reminders

          - Ask: "Have you triggered the QA pipeline?"
          - Flag all modified fixtures as needing a reviewer, checking
            each one against the base branch first

          ### Verify Before Flagging

          When a diff modifies an existing structure, verify the current
          state from an authoritative source before flagging a discrepancy.
        BASELINE
      end

      let(:verbatim_content) do
        <<~CONTENT
          # QA Principles

          ## Checklist

          ### Process Reminders

          - Do thing
          - Ask: "Have you triggered the QA pipeline?"
          - Flag all modified fixtures as needing a reviewer, checking
            each one against the base branch first

          ### Verify Before Flagging

          When a diff modifies an existing structure, verify the current
          state from an authoritative source before flagging a discrepancy.
        CONTENT
      end

      before do
        FileUtils.mkdir_p(File.join(tmpdir, '.ai/principles/baselines'))
        File.write(File.join(tmpdir, '.ai/principles/baselines/qa.md'), baseline_content)
      end

      context 'when the output includes every baseline line verbatim' do
        before do
          allow(sync.workflow).to receive(:distill).and_return(verbatim_content)
        end

        it 'accepts the content on the first attempt' do
          expect(distill).to include('Have you triggered the QA pipeline?')
          expect(sync.workflow).to have_received(:distill).once
        end
      end

      context 'when the output integrates baseline rules under a different heading' do
        # Rule 15 allows adapting placement/headings when integrating into
        # an existing same-topic subsection; only the rule lines are locked.
        let(:relocated_content) do
          verbatim_content.sub('### Process Reminders', '### Review Process')
        end

        before do
          allow(sync.workflow).to receive(:distill).and_return(relocated_content)
        end

        it 'accepts the content (headings are exempt from the verbatim check)' do
          expect(distill).to include('### Review Process')
          expect(sync.workflow).to have_received(:distill).once
        end
      end

      context 'when the output rewords a baseline rule' do
        let(:corrupted_content) do
          verbatim_content.sub('Have you triggered the QA pipeline?', 'Did you run QA?')
        end

        before do
          allow(sync.workflow).to receive(:distill).and_return(corrupted_content, verbatim_content)
        end

        it 'treats the drift as failure, logs it, and retries', :aggregate_failures do
          expect { distill }
            .to output(/altered, omitted, or duplicated 1 baseline rule/).to_stderr
          expect(sync.workflow).to have_received(:distill).twice
        end
      end

      context 'when the output omits a baseline rule' do
        let(:corrupted_content) do
          verbatim_content.sub("- Ask: \"Have you triggered the QA pipeline?\"\n", '')
        end

        before do
          allow(sync.workflow).to receive(:distill).and_return(corrupted_content, verbatim_content)
        end

        it 'treats the omission as failure and retries' do
          expect { distill }
            .to output(/altered, omitted, or duplicated 1 baseline rule/).to_stderr
          expect(sync.workflow).to have_received(:distill).twice
        end
      end

      context 'when the output re-wraps a multi-line baseline rule' do
        # Identical text with different wrapping is not corruption. A
        # line-level check rejected this deterministically, burning every
        # retry on byte-identical text (observed with the hard-wrapped
        # database-fundamentals baseline).
        let(:rewrapped_content) do
          verbatim_content.sub(
            "- Flag all modified fixtures as needing a reviewer, checking\n  " \
              "each one against the base branch first",
            '- Flag all modified fixtures as needing a reviewer, checking each one against the base branch first'
          )
        end

        before do
          allow(sync.workflow).to receive(:distill).and_return(rewrapped_content)
        end

        it 'accepts the content on the first attempt' do
          expect(distill).to include('Flag all modified fixtures')
          expect(sync.workflow).to have_received(:distill).once
        end
      end

      context 'when the output re-flows a baseline paragraph onto one line' do
        let(:rewrapped_content) do
          verbatim_content.sub(
            "When a diff modifies an existing structure, verify the current\n" \
              "state from an authoritative source before flagging a discrepancy.",
            'When a diff modifies an existing structure, verify the current ' \
              'state from an authoritative source before flagging a discrepancy.'
          )
        end

        before do
          allow(sync.workflow).to receive(:distill).and_return(rewrapped_content)
        end

        it 'accepts the content on the first attempt' do
          expect(distill).to include('verify the current')
          expect(sync.workflow).to have_received(:distill).once
        end
      end

      context 'when the output duplicates a baseline sentence fragment' do
        # The observed corruption emitted a baseline sentence fragment twice
        # right after its own bullet; the fragment joins the bullet's logical
        # unit and corrupts it, so the unit no longer matches the baseline.
        let(:corrupted_content) do
          verbatim_content.sub(
            "  each one against the base branch first\n",
            "  each one against the base branch first\n  " \
              "each one against the base branch first\n"
          )
        end

        before do
          allow(sync.workflow).to receive(:distill).and_return(corrupted_content, verbatim_content)
        end

        it 'treats the duplication as failure and retries' do
          expect { distill }
            .to output(/altered, omitted, or duplicated 1 baseline rule/).to_stderr
          expect(sync.workflow).to have_received(:distill).twice
        end
      end

      context 'when the output duplicates an entire baseline rule' do
        # Presence alone is not enough: each baseline rule must appear
        # exactly once.
        let(:corrupted_content) do
          "#{verbatim_content}\n- Ask: \"Have you triggered the QA pipeline?\"\n"
        end

        before do
          allow(sync.workflow).to receive(:distill).and_return(corrupted_content, verbatim_content)
        end

        it 'treats the duplication as failure and retries' do
          expect { distill }
            .to output(/altered, omitted, or duplicated 1 baseline rule/).to_stderr
          expect(sync.workflow).to have_received(:distill).twice
        end
      end

      context 'when baseline drift persists on every attempt' do
        let(:corrupted_content) do
          verbatim_content.sub('Have you triggered the QA pipeline?', 'Did you run QA?')
        end

        before do
          allow(sync.workflow).to receive(:distill).and_return(corrupted_content)
        end

        it 'returns nil after DISTILL_MAX_RETRIES attempts', :aggregate_failures do
          expect { distill }.to output(/Duo failed after #{described_class::DISTILL_MAX_RETRIES} attempts/o).to_stderr
          expect(distill).to be_nil
          expect(sync.workflow).to have_received(:distill)
            .exactly(described_class::DISTILL_MAX_RETRIES).times
        end
      end
    end
  end

  describe 'MAX_CONCURRENT_DISTILLATIONS' do
    subject(:cap) { described_class::MAX_CONCURRENT_DISTILLATIONS }

    it 'is a positive integer' do
      expect(cap).to be_a(Integer).and(be_positive)
    end

    it 'is small enough to avoid overwhelming the Duo API' do
      expect(cap).to be <= 8
    end
  end

  describe '.parse_options' do
    def parse(*args)
      original_argv = ARGV.dup
      ARGV.replace(args)
      sync.parse_options
    ensure
      ARGV.replace(original_argv)
    end

    it 'defaults push to false (absent from result)' do
      expect(parse[:push]).to be_nil
    end

    it 'sets push: true when --push is passed' do
      expect(parse('--push')[:push]).to be true
    end

    it 'sets force: true when --force is passed' do
      expect(parse('--force')[:force]).to be true
    end

    it 'sets dry_run: true when --dry-run is passed' do
      expect(parse('--dry-run')[:dry_run]).to be true
    end

    it 'sets only: array when --only is passed' do
      expect(parse('--only', 'backend,qa')[:only]).to eq(%w[backend qa])
    end

    it 'sets rewrite: true when --rewrite is passed' do
      expect(parse('--rewrite')[:rewrite]).to be true
    end

    it 'sets check_duo_instructions: true when --check-duo-instructions is passed' do
      expect(parse('--check-duo-instructions')[:check_duo_instructions]).to be true
    end

    it 'sets reconcile_duo_instructions: true when --reconcile-duo-instructions is passed' do
      expect(parse('--reconcile-duo-instructions')[:reconcile_duo_instructions]).to be true
    end

    it 'sets warn_stale: true when --warn-stale is passed' do
      expect(parse('--check-duo-instructions', '--warn-stale')[:warn_stale]).to be true
    end
  end

  describe '.check_duo_instructions' do
    let(:result) do
      Gitlab::PrinciplesDistiller::Sync::DuoInstructions::Result.new(
        stale: stale, malformed: malformed, pending: [], orphaned: orphaned
      )
    end

    let(:stale) { [] }
    let(:malformed) { [] }
    let(:orphaned) { [] }

    before do
      allow(sync.manifest).to receive(:load)
      allow(sync.manifest).to receive(:problematic_duo_review_instructions).and_return(result)
    end

    context 'without --warn-stale (strict)' do
      context 'when a fence is stale' do
        let(:stale) { ['qa'] }

        it 'fails the guard' do
          expect(sync).to receive(:exit).with(1)

          expect { sync.check_duo_instructions }.to output(/Stale: qa/).to_stderr
        end
      end
    end

    context 'with --warn-stale' do
      context 'when a fence is only stale' do
        let(:stale) { ['qa'] }

        it 'warns without failing the guard', :aggregate_failures do
          expect(sync).not_to receive(:exit)

          expect { sync.check_duo_instructions(warn_stale: true) }
            .to output(/stale on this ref: qa.*No action needed/m).to_stderr
        end
      end

      context 'when a fence is malformed' do
        let(:malformed) { ['qa'] }

        it 'still fails the guard regardless of the flag' do
          expect(sync).to receive(:exit).with(1)

          expect { sync.check_duo_instructions(warn_stale: true) }.to output(/Malformed: qa/).to_stderr
        end
      end

      context 'when a fence is orphaned' do
        let(:orphaned) { ['qa'] }

        it 'still fails the guard regardless of the flag' do
          expect(sync).to receive(:exit).with(1)

          expect { sync.check_duo_instructions(warn_stale: true) }.to output(/Orphaned: qa/).to_stderr
        end
      end
    end
  end

  describe '.reconcile_duo_instructions' do
    before do
      allow(sync).to receive(:banner)
      allow(sync.manifest).to receive(:load)
    end

    context 'with --push' do
      before do
        allow(sync.manifest).to receive(:auto_mr_config)
          .and_return({ 'branch_prefix' => 'docs-sync/principles' })
      end

      # The projection is deferred to the freshly cut branch inside
      # create_reconcile_mr_from_working_tree (which receives the manifest to
      # regenerate against the branch's base), so reconcile_duo_instructions
      # must NOT regenerate on the pipeline-SHA working tree first.
      it 'defers regeneration to the fresh branch and opens the MR', :aggregate_failures do
        expect(sync.manifest).not_to receive(:generate_duo_review_instructions)
        expect(sync).to receive(:create_reconcile_mr_from_working_tree)
          .with({ 'branch_prefix' => 'docs-sync/principles' }, sync.manifest)

        sync.reconcile_duo_instructions(push: true)
      end
    end

    context 'without --push' do
      context 'when the fences are already up to date' do
        before do
          allow(sync.manifest).to receive(:generate_duo_review_instructions).and_return(false)
        end

        it 'does not open an MR' do
          expect(sync).not_to receive(:create_reconcile_mr_from_working_tree)

          expect { sync.reconcile_duo_instructions(push: false) }
            .to output(/already up to date/).to_stdout
        end
      end

      context 'when the fences changed' do
        before do
          allow(sync.manifest).to receive(:generate_duo_review_instructions).and_return(true)
        end

        it 'only rewrites on disk (never re-distilling)' do
          expect(sync).not_to receive(:create_reconcile_mr_from_working_tree)

          expect { sync.reconcile_duo_instructions(push: false) }
            .to output(/\[LOCAL\].*Pass --push/m).to_stdout
        end
      end
    end
  end
end
