# frozen_string_literal: true

require 'spec_helper'
require_relative '../../support/tmpdir'
require_relative '../../../lib/gitlab/principles_distiller/sync'

RSpec.describe Gitlab::PrinciplesDistiller::Sync do
  include TmpdirHelper

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

      it 'writes no file (so its existing source_checksum, if any, is left untouched)' do
        sync.distill_and_write_principles(affected)

        expect(File.exist?(File.join(principles_dir, 'qa.md'))).to be false
      end
    end

    context 'when one principle succeeds and another fails' do
      let(:manifest) do
        {
          'principles' => {
            'qa' => { 'sources' => [{ 'path' => 'doc/development/testing_guide/best_practices.md' }] },
            'other' => { 'sources' => [{ 'path' => 'doc/development/other.md' }] }
          }
        }
      end

      let(:affected) do
        {
          'qa' => { config: manifest.dig('principles', 'qa'), changed_sources: [] },
          'other' => { config: manifest.dig('principles', 'other'), changed_sources: [] }
        }
      end

      before do
        allow(sync).to receive(:parallel_distill).and_return(
          'qa' => [existing_content, distilled_content],
          'other' => [nil, nil]
        )
      end

      it 'writes and reports only the successful principle, leaving the failed one untouched',
        :aggregate_failures do
        updated, failed = sync.distill_and_write_principles(affected)

        expect(updated.keys).to eq(['qa'])
        expect(failed).to eq(['other'])
        expect(File.exist?(File.join(principles_dir, 'qa.md'))).to be true
        expect(File.exist?(File.join(principles_dir, 'other.md'))).to be false
      end
    end

    # Regression: a re-distillation that produces the same checklist must be skipped, not emitted as a frontmatter-only
    # MR (new source_checksum / distilled_at_sha but an identical body).
    # In production `current` is read from disk WITH the auto-generated header and authoritative sources footer intact
    # (strip_frontmatter removes only the YAML block), while `updated` is the raw LLM checklist WITHOUT that footer.
    # The meaningful? gate must therefore compare the fully-assembled body against `current`; hence `existing_on_disk`
    # includes the footer to mirror real on-disk content.
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

  # Covers the partial-failure ordering: a distillation failure must not discard principles that succeeded in the same
  # run.
  describe '.distill_and_publish' do
    let(:affected) { { 'qa' => { config: {} } } }

    before do
      Gitlab::PrinciplesDistiller::Workspace.path = tmpdir
      allow(sync.workflow).to receive(:validate_config!)
      allow(sync.manifest).to receive_messages(load: nil, affected_principles: affected, auto_mr_config: {})
      allow(sync).to receive(:regenerate_static_artifacts)
    end

    def run_report
      path = File.join(tmpdir, described_class::RUN_REPORT_PATH)
      File.exist?(path) ? File.read(path) : nil
    end

    context 'with a partial success (some contents, some failures)' do
      let(:options) { { push: true } }

      before do
        allow(sync).to receive(:distill).and_return([{ 'qa' => 'content' }, ['other']])
        allow(sync).to receive(:create_branch_and_mr)
      end

      # The status is asserted, not just the SystemExit: a bare raise_error(SystemExit) also passes for `exit 0`, which
      # would silently disable the scheduled Slack alert (it fires on a non-zero exit).
      it 'publishes the successful principles and still exits non-zero', :aggregate_failures do
        expect { sync.distill_and_publish(options) }.to raise_error(SystemExit) { |error|
          expect(error.status).to eq(1)
        }
        expect(sync).to have_received(:create_branch_and_mr)
          .with({ 'qa' => 'content' }, affected, anything, failed: ['other'])
      end

      # The Slack alert job reads these to name the failed principles instead of posting a generic "the job failed".
      it 'writes the failed principles to the dotenv report', :aggregate_failures do
        expect { sync.distill_and_publish(options) }.to raise_error(SystemExit) { |error|
          expect(error.status).to eq(1)
        }

        expect(run_report).to include('AI_PRINCIPLES_FAILED_COUNT=1')
        expect(run_report).to include('AI_PRINCIPLES_FAILED_NAMES=other')
        expect(run_report).to include('AI_PRINCIPLES_PUBLISHED_COUNT=1')
      end
    end

    context 'with total failure (no contents, some failures)' do
      let(:options) { { push: true } }

      before do
        allow(sync).to receive(:distill).and_return([{}, ['qa']])
        allow(sync).to receive(:create_branch_and_mr)
      end

      it 'does not publish and still exits non-zero', :aggregate_failures do
        expect { sync.distill_and_publish(options) }.to raise_error(SystemExit) { |error|
          expect(error.status).to eq(1)
        }
        expect(sync).not_to have_received(:create_branch_and_mr)
      end
    end

    context 'with a clean run (contents, no failures)' do
      let(:options) { { push: true } }

      before do
        allow(sync).to receive(:distill).and_return([{ 'qa' => 'content' }, []])
        allow(sync).to receive(:create_branch_and_mr)
      end

      it 'publishes and exits zero', :aggregate_failures do
        expect { sync.distill_and_publish(options) }.not_to raise_error
        expect(sync).to have_received(:create_branch_and_mr)
          .with({ 'qa' => 'content' }, affected, anything, failed: [])
      end

      # The report is still written (so the artifact uploader always has a file to pick up), but with no failed names,
      # which is what the Slack job tests, so it never claims a partial failure on a run that had none.
      it 'writes the dotenv report with no failed principles', :aggregate_failures do
        sync.distill_and_publish(options)

        expect(run_report).to include('AI_PRINCIPLES_FAILED_COUNT=0')
        expect(run_report).to include("AI_PRINCIPLES_FAILED_NAMES=\n")
        expect(run_report).to include('AI_PRINCIPLES_PUBLISHED_COUNT=1')
      end
    end

    context 'when no principles are affected' do
      let(:options) { { push: true } }
      let(:affected) { {} }

      # The scheduled job's normal green path returns before distillation, so the report has to be written here too or
      # the uploader logs `no matching files` / `No files to upload` on every clean weekly run.
      it 'writes the dotenv report and exits zero', :aggregate_failures do
        expect { sync.distill_and_publish(options) }.not_to raise_error

        expect(run_report).to include('AI_PRINCIPLES_FAILED_COUNT=0')
        expect(run_report).to include('AI_PRINCIPLES_PUBLISHED_COUNT=0')
      end
    end
  end

  # The three stages of the split CI pipeline (see gitlab-org/gitlab#607365): generate emits one distill job per
  # affected principle, each distill job records its own outcome as an artifact, and collect fans them back in and
  # publishes.
  # Splitting this way gives every principle its own job timeout, so one slow principle can no longer time out a shared
  # budget and discard every other principle's completed work.
  describe 'split pipeline stages' do
    let(:artifacts_dir) { File.join(tmpdir, described_class::ARTIFACTS_DIR) }

    before do
      Gitlab::PrinciplesDistiller::Workspace.path = tmpdir
      allow(sync.workflow).to receive(:validate_config!)
    end

    describe '.generate_child_pipeline' do
      subject(:generate) { sync.generate_child_pipeline(options) }

      let(:options) { {} }
      let(:affected) { { 'alpha' => { config: {} }, 'beta' => { config: {} } } }

      before do
        allow(sync.manifest).to receive_messages(load: nil, affected_principles: affected)
      end

      def child_pipeline
        YAML.safe_load(File.read(File.join(tmpdir, described_class::CHILD_PIPELINE_PATH)))
      end

      it 'writes a child pipeline with one distill job per affected principle' do
        generate

        expect(child_pipeline.keys).to include('distill:alpha', 'distill:beta')
      end

      # The whole point of the generate job is that it is cheap: all the expensive, timeout-prone work moves into the
      # per-principle jobs.
      it 'triggers no distillation' do
        # Stubbed in the example, not a `before`: it is the subject of this assertion rather than shared setup.
        allow(sync).to receive(:build_distilled_contents)

        generate

        expect(sync).not_to have_received(:build_distilled_contents)
      end

      context 'when --force and --only are passed' do
        let(:options) { { force: true, only: ['alpha'] } }

        it 'passes them through to the drift scan' do
          generate

          expect(sync.manifest).to have_received(:affected_principles).with(force: true, only: ['alpha'])
        end
      end

      # A child pipeline with no jobs is invalid, and the collect job comes from the included template, so the clean
      # path stays the ordinary path rather than a special case in the parent pipeline.
      context 'when no principles are affected' do
        let(:affected) { {} }

        it 'still writes a pipeline, with no distill jobs', :aggregate_failures do
          expect { generate }.to output(/All principles are up to date/).to_stdout

          expect(child_pipeline.keys.grep(/\Adistill:/)).to be_empty
        end
      end
    end

    describe '.distill_one' do
      let(:config) { { 'sources' => [{ 'path' => 'doc/qa.md' }] } }
      # [contents, failed] as build_distilled_contents returns it.
      # Each context below overrides this to pick the outcome it exercises.
      let(:distilled) { [{ 'qa' => 'body' }, []] }

      before do
        allow(sync.manifest).to receive_messages(load: nil, principle_config: config,
          new_sources_for: [{ 'path' => 'doc/new.md' }])
        allow(sync).to receive(:build_distilled_contents).and_return(distilled)
      end

      def status_of(name)
        File.read(File.join(artifacts_dir, "#{name}.status"))
      end

      context 'when the principle distills to new content' do
        it 'passes newly declared sources to distillation' do
          sync.distill_one('qa')

          expect(sync).to have_received(:build_distilled_contents).with(
            'qa' => { config: config, new_sources: [{ 'path' => 'doc/new.md' }] }
          )
        end

        it 'records an updated status with the assembled content', :aggregate_failures do
          sync.distill_one('qa')

          expect(status_of('qa')).to eq(described_class::Artifacts::STATUS_UPDATED)
          expect(File.read(File.join(artifacts_dir, 'qa.md'))).to eq('body')
        end

        # Publishing is the fan-in's job: building the per-team MRs shares a single working tree and cannot be
        # parallelized the way distillation can.
        it 'publishes nothing' do
          allow(sync).to receive(:create_branch_and_mr)

          sync.distill_one('qa')

          expect(sync).not_to have_received(:create_branch_and_mr)
        end
      end

      # A clean run that produced no meaningful diff is a healthy outcome and must stay distinct from a failure, or it
      # would reach the Slack alert.
      context 'when the principle has no meaningful changes' do
        let(:distilled) { [{}, []] }

        it 'records an unchanged status and exits zero', :aggregate_failures do
          expect { sync.distill_one('qa') }.not_to raise_error

          expect(status_of('qa')).to eq(described_class::Artifacts::STATUS_UNCHANGED)
        end
      end

      context 'when the principle fails after retries' do
        let(:distilled) { [{}, ['qa']] }

        # The status artifact is written BEFORE the non-zero exit, and the CI
        # job declares `artifacts: when: always`.
        # Without both, the collect job would see no artifact and silently downgrade a genuine failure to "job never
        # ran".
        it 'records a failed status and then exits non-zero', :aggregate_failures do
          expect { sync.distill_one('qa') }.to raise_error(SystemExit) { |e| expect(e.status).to eq(1) }

          expect(status_of('qa')).to eq(described_class::Artifacts::STATUS_FAILED)
        end
      end

      # A generated pipeline naming a principle the manifest does not have means the two have diverged.
      # Succeeding quietly would let collect report it as "never ran" and skip it every single week.
      context 'when the principle is not in the manifest' do
        let(:config) { nil }

        it 'aborts' do
          expect { sync.distill_one('nope') }
            .to raise_error(SystemExit)
            .and output(/unknown principle 'nope'/).to_stderr
        end
      end
    end

    describe '.collect' do
      let(:expected) { %w[alpha beta gamma] }
      let(:affected) { { 'alpha' => { config: {} } } }

      before do
        FileUtils.mkdir_p(artifacts_dir)
        allow(sync.manifest).to receive_messages(load: nil, affected_principles: affected, auto_mr_config: {})
        allow(sync).to receive(:create_branch_and_mr)
      end

      def write_artifact(name, status, content: nil)
        File.write(File.join(artifacts_dir, "#{name}.status"), status)
        File.write(File.join(artifacts_dir, "#{name}.md"), content) if content
      end

      def run_report
        File.read(File.join(tmpdir, described_class::RUN_REPORT_PATH))
      end

      context 'when one principle succeeded, one failed, and one never ran' do
        before do
          write_artifact('alpha', described_class::Artifacts::STATUS_UPDATED, content: 'alpha body')
          write_artifact('beta', described_class::Artifacts::STATUS_FAILED)
          # gamma writes nothing: its job never completed.
        end

        # This is the loss the split exists to prevent: alpha publishes even though beta failed and gamma's job never
        # finished.
        it 'publishes what succeeded and exits non-zero', :aggregate_failures do
          expect { sync.collect(expected, push: true) }.to raise_error(SystemExit) { |e| expect(e.status).to eq(1) }

          expect(sync).to have_received(:create_branch_and_mr)
            .with({ 'alpha' => 'alpha body' }, affected, anything, failed: ['beta'], not_run: ['gamma'])
        end

        # Distinct dotenv vars, not overloaded failure ones, so the Slack job can word "Duo could not distill these" and
        # "these jobs never ran" differently.
        it 'reports the two abnormal states separately' do
          expect { sync.collect(expected, push: true) }.to raise_error(SystemExit)

          expect(run_report).to include(
            'AI_PRINCIPLES_FAILED_NAMES=beta',
            'AI_PRINCIPLES_NOT_RUN_NAMES=gamma',
            'AI_PRINCIPLES_PUBLISHED_COUNT=1'
          )
        end
      end

      # A principle whose job never ran has not been shown to be undistillable, and its checksum is untouched, so the
      # next scheduled run simply re-attempts it.
      # Failing the run would alert on normal operation.
      context 'when a principle never ran but nothing actually failed' do
        before do
          write_artifact('alpha', described_class::Artifacts::STATUS_UPDATED, content: 'alpha body')
          write_artifact('beta', described_class::Artifacts::STATUS_UNCHANGED)
        end

        it 'publishes and exits zero', :aggregate_failures do
          expect { sync.collect(expected, push: true) }.not_to raise_error

          expect(sync).to have_received(:create_branch_and_mr)
            .with({ 'alpha' => 'alpha body' }, affected, anything, failed: [], not_run: ['gamma'])
        end
      end

      # Collect owns publishing precisely so distillation can be parallel; it must never trigger a workflow itself.
      context 'with a principle to publish' do
        before do
          write_artifact('alpha', described_class::Artifacts::STATUS_UPDATED, content: 'alpha body')
        end

        it 'does not publish without --push' do
          expect { sync.collect(expected, push: false) }
            .to output(/\[LOCAL\].*Pass --push/m).to_stdout

          expect(sync).not_to have_received(:create_branch_and_mr)
        end

        it 'distills nothing' do
          # Stubbed in the example, not a `before`: it is the subject of this assertion rather than shared setup.
          allow(sync).to receive(:build_distilled_contents)

          expect { sync.collect(expected, push: true) }.not_to raise_error
          expect(sync).not_to have_received(:build_distilled_contents)
        end
      end

      context 'when every distill job reported no meaningful change' do
        let(:expected) { ['alpha'] }

        before do
          write_artifact('alpha', described_class::Artifacts::STATUS_UNCHANGED)
        end

        it 'opens no MR and exits zero', :aggregate_failures do
          expect { sync.collect(expected, push: true) }.not_to raise_error

          expect(sync).not_to have_received(:create_branch_and_mr)
          expect(run_report).to include('AI_PRINCIPLES_PUBLISHED_COUNT=0')
        end
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
    # `distill_principle` is private (it's an internal step of parallel_distill), so specs reach it via `send`.
    # The retry loop is the most failure-prone control flow in the gem: any of the three Duo invocations can return nil,
    # return content missing the required heading, or succeed.
    subject(:distill) { sync.send(:distill_principle, 'qa', config, new_sources: new_sources) }

    let(:config) { { 'sources' => [{ 'path' => 'doc/qa.md' }] } }
    let(:new_sources) { [] }
    let(:valid_content) { "# QA Principles\n\n## Checklist\n\n- Do thing\n" }

    before do
      Gitlab::PrinciplesDistiller::Workspace.path = tmpdir
      FileUtils.mkdir_p(File.join(tmpdir, 'doc'))
      File.write(File.join(tmpdir, 'doc/qa.md'), 'source content')

      # Bypass real waits between retries.
      # We assert the call site separately rather than letting the test stall for 5+ minutes.
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

      context 'with newly declared sources' do
        let(:new_sources) { [{ 'path' => 'doc/new.md' }] }

        it 'forwards them to the workflow' do
          distill

          expect(sync.workflow).to have_received(:distill)
            .with('qa', config, new_sources: new_sources)
        end
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

    # Mechanical guard for prompt rule 15: baseline rules must appear verbatim, exactly once.
    # A re-distillation once relocated AND corrupted a baseline section (duplicated sentence fragment, broken
    # sub-bullet) despite the verbatim instruction; prompt-only enforcement is not enough, so baseline drift must
    # consume a retry instead of publishing.
    # The check compares normalized logical units (bullets/paragraphs with wrapping and whitespace collapsed), not
    # physical lines: the agent routinely re-flows hard-wrapped lines, and identical text with different wrapping is not
    # corruption.
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
        # Rule 15 allows adapting placement/headings when integrating into an existing same-topic subsection; only the
        # rule lines are locked.
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

        it 'uses the short deterministic backoff, not the long Gitaly one', :aggregate_failures do
          distill

          expect(sync.workflow).to have_received(:sleep_with_heartbeat)
            .with(described_class::DISTILL_BASELINE_DRIFT_BACKOFF_SECONDS, anything, anything)
          expect(sync.workflow).not_to have_received(:sleep_with_heartbeat)
            .with(described_class::DISTILL_RETRY_BACKOFF_SECONDS[0], anything, anything)
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
        # Identical text with different wrapping is not corruption.
        # A line-level check rejected this deterministically, burning every retry on byte-identical text (observed with
        # the hard-wrapped database-fundamentals baseline).
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

      context 'when the output renders a baseline paragraph as a bullet' do
        # Regression: the database-fundamentals baseline stores the "When a diff modifies..." rule as a bare paragraph
        # that precedes nested sub-bullets, but every reasonable distillation renders it as a bullet so the sub-bullets
        # attach.
        # Keeping the leading list marker in the normalized unit made the two forms compare unequal, so the guard
        # flagged drift on byte-identical rule text and burned every retry (which timed out the weekly
        # ai-principles-sync job).
        # The marker is presentation, not content, so this must be accepted.
        let(:bulletized_content) do
          verbatim_content.sub(
            'When a diff modifies an existing structure',
            '- When a diff modifies an existing structure'
          )
        end

        before do
          allow(sync.workflow).to receive(:distill).and_return(bulletized_content)
        end

        it 'accepts the content on the first attempt' do
          expect(distill).to include('When a diff modifies an existing structure')
          expect(sync.workflow).to have_received(:distill).once
        end
      end

      context 'when the output duplicates a baseline sentence fragment' do
        # The observed corruption emitted a baseline sentence fragment twice right after its own bullet; the fragment
        # joins the bullet's logical unit and corrupts it, so the unit no longer matches the baseline.
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
        # Presence alone is not enough: each baseline rule must appear exactly once.
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

      context 'when the output appends a trailing period to a baseline rule' do
        # The agent routinely appends a period while rephrasing a baseline rule into a sentence; that punctuation is
        # presentation, not the rule's identity, and must not consume a retry.
        let(:punctuated_content) do
          verbatim_content.sub(
            'each one against the base branch first',
            'each one against the base branch first.'
          )
        end

        before do
          allow(sync.workflow).to receive(:distill).and_return(punctuated_content)
        end

        it 'accepts the content on the first attempt' do
          expect(distill).to include('each one against the base branch first.')
          expect(sync.workflow).to have_received(:distill).once
        end
      end
    end

    context 'when the baseline has a preamble before its own ## Checklist heading' do
      # Regression: `Workflow#build_goal` instructs the agent to "Output ONLY the checklist content. No preamble, no
      # thinking, no trailing notes."
      # A baseline's own title/prerequisite-note/framing-sentence preamble is document scaffolding, not a rule, so
      # requiring its verbatim reproduction is an unsatisfiable guard.
      let(:config) do
        {
          'sources' => [{ 'path' => 'doc/qa.md' }],
          'baseline' => '.ai/principles/baselines/qa.md'
        }
      end

      let(:baseline_content) do
        <<~BASELINE
          # QA Baseline

          > **Prerequisite:** Read the other guide first.

          This baseline answers only one question: which pipeline to run.

          ---

          ## Checklist

          ### Process Reminders

          - Ask: "Have you triggered the QA pipeline?"
        BASELINE
      end

      let(:checklist_only_content) do
        <<~CONTENT
          # QA Principles

          ## Checklist

          ### Process Reminders

          - Ask: "Have you triggered the QA pipeline?"
        CONTENT
      end

      before do
        FileUtils.mkdir_p(File.join(tmpdir, '.ai/principles/baselines'))
        File.write(File.join(tmpdir, '.ai/principles/baselines/qa.md'), baseline_content)
        allow(sync.workflow).to receive(:distill).and_return(checklist_only_content)
      end

      it 'accepts output that omits the preamble and the --- divider on the first attempt' do
        expect(distill).to include('Have you triggered the QA pipeline?')
        expect(sync.workflow).to have_received(:distill).once
      end
    end

    context 'when a baseline path also appears in the appended Authoritative sources footer' do
      # Regression: `Sync#assemble_distilled_body` appends an "## Authoritative sources" footer listing every SSOT path.
      # When a baseline also lists that path in its checklist, it legitimately appears twice in the fully-assembled
      # file; the guard must not penalize the tool's own output for that (observed with documentation-topics, job
      # 15601793108).
      # `baseline_drift` runs on the raw agent output before the footer is normally appended, so this covers the case
      # where the agent emits a footer anyway.
      let(:config) do
        {
          'sources' => [{ 'path' => 'doc/topic_types/concept.md' }],
          'baseline' => '.ai/principles/baselines/documentation-topics.md'
        }
      end

      let(:baseline_content) do
        <<~BASELINE
          ## Documentation Structure

          - doc/topic_types/concept.md
        BASELINE
      end

      let(:content_with_footer) do
        <<~CONTENT
          # Documentation Topics Principles

          ## Checklist

          ## Documentation Structure

          - doc/topic_types/concept.md

          ## Authoritative sources

          For the full picture, see:

          - doc/topic_types/concept.md
        CONTENT
      end

      before do
        FileUtils.mkdir_p(File.join(tmpdir, '.ai/principles/baselines'))
        File.write(File.join(tmpdir, '.ai/principles/baselines/documentation-topics.md'), baseline_content)
        allow(sync.workflow).to receive(:distill).and_return(content_with_footer)
      end

      it 'accepts the content on the first attempt (footer occurrence does not count as duplication)' do
        expect(distill).to include('doc/topic_types/concept.md')
        expect(sync.workflow).to have_received(:distill).once
      end
    end

    context 'when a baseline rule is genuinely duplicated and the output also has a sources footer' do
      # Guard-integrity check: scoping the comparison to the checklist body must not swallow real duplication that
      # occurs before the footer.
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
        BASELINE
      end

      let(:verbatim_content) do
        <<~CONTENT
          # QA Principles

          ## Checklist

          ### Process Reminders

          - Ask: "Have you triggered the QA pipeline?"
        CONTENT
      end

      let(:corrupted_content) do
        <<~CONTENT
          #{verbatim_content}
          - Ask: "Have you triggered the QA pipeline?"

          ## Authoritative sources

          For the full picture, see:

          - doc/qa.md
        CONTENT
      end

      before do
        FileUtils.mkdir_p(File.join(tmpdir, '.ai/principles/baselines'))
        File.write(File.join(tmpdir, '.ai/principles/baselines/qa.md'), baseline_content)
        allow(sync.workflow).to receive(:distill).and_return(corrupted_content, verbatim_content)
      end

      it 'still treats the duplication as failure and retries' do
        expect { distill }
          .to output(/altered, omitted, or duplicated 1 baseline rule/).to_stderr
        expect(sync.workflow).to have_received(:distill).twice
      end
    end
  end

  describe '.repair_escape_artifacts' do
    subject(:repair) { sync.send(:repair_escape_artifacts, content, config, log_warn) }

    let(:log_warn) { instance_double(Proc) }
    let(:source_content) { '' }
    let(:config) { { 'sources' => [{ 'path' => 'doc/source.md' }] } }

    before do
      Gitlab::PrinciplesDistiller::Workspace.path = tmpdir
      FileUtils.mkdir_p(File.join(tmpdir, 'doc'))
      File.write(File.join(tmpdir, 'doc/source.md'), source_content)
    end

    context 'with entity escapes outside fenced code blocks' do
      let(:content) do
        "# Principles\n\n- Run `tool &lt;argument&gt;` &amp; inspect `&quot;output&quot;`&#39;s value.\n"
      end

      it 'repairs the content and warns with the affected line number' do
        expect(log_warn).to receive(:call).with('  WARNING: repaired escape artifacts on line(s) 3')

        expect(repair).to eq("# Principles\n\n- Run `tool <argument>` & inspect `\"output\"`'s value.\n")
      end
    end

    context 'with entity escapes in a fenced code block' do
      let(:content) do
        <<~MARKDOWN
          # Principles

          ```markdown
          Use `&lt;placeholder&gt;` in documentation.
          ```
        MARKDOWN
      end

      it 'preserves the example without warning' do
        expect(log_warn).not_to receive(:call)

        expect(repair).to eq(content)
      end
    end

    context 'with an entity escape copied from the SSOT' do
      let(:content) { "# Principles\n\n- Use the entity code `&lt;` for a literal angle bracket.\n" }
      let(:source_content) { 'Use the entity code `&lt;` for a literal angle bracket.' }

      it 'preserves the SSOT content without warning' do
        expect(log_warn).not_to receive(:call)

        expect(repair).to eq(content)
      end
    end

    context 'with backslash escapes outside fenced code blocks' do
      let(:content) { "# Principles\n\n- Add the `~\\\"coach will finish\\\"` label for `\\'name\\'`, `\\<tag\\>`.\n" }

      it 'repairs the content and warns with the affected line number' do
        expect(log_warn).to receive(:call).with('  WARNING: repaired escape artifacts on line(s) 3')

        expect(repair).to eq("# Principles\n\n- Add the `~\"coach will finish\"` label for `'name'`, `<tag>`.\n")
      end
    end

    context 'with backslash escapes in a fenced code block' do
      let(:content) do
        <<~MARKDOWN
          # Principles

          ```markdown
          Add the `~\\"coach will finish\\"` label.
          ```
        MARKDOWN
      end

      it 'preserves the example without warning' do
        expect(log_warn).not_to receive(:call)

        expect(repair).to eq(content)
      end
    end

    context 'with a backslash escape copied from the SSOT' do
      let(:content) { "# Principles\n\n- Use `\\<placeholder\\>` in documentation.\n" }
      let(:source_content) { 'Use `\<placeholder\>` in documentation.' }

      it 'preserves the SSOT content without warning' do
        expect(log_warn).not_to receive(:call)

        expect(repair).to eq(content)
      end
    end

    context 'with escaped backticks in a nested inline-code span' do
      let(:content) { "# Principles\n\n- Use `Use \\`otherFieldName\\`` as the deprecation reason.\n" }

      it 'leaves the nested span unchanged without warning' do
        expect(log_warn).not_to receive(:call)

        expect(repair).to eq(content)
      end
    end

    context 'with legitimate Markdown escapes' do
      let(:content) { "# Principles\n\n- Preserve \\*, \\_, \\|, and \\` in prose.\n" }

      it 'leaves the escapes unchanged without warning' do
        expect(log_warn).not_to receive(:call)

        expect(repair).to eq(content)
      end
    end

    context 'with entity and backslash escapes on one line' do
      let(:content) { "# Principles\n\n- Run `tool &lt;argument&gt;` with `\\\"quoted\\\"` output.\n" }

      it 'repairs the content and lists the line once' do
        expect(log_warn).to receive(:call).with('  WARNING: repaired escape artifacts on line(s) 3')

        expect(repair).to eq("# Principles\n\n- Run `tool <argument>` with `\"quoted\"` output.\n")
      end
    end

    context 'with clean content' do
      let(:content) { "# Principles\n\n- Run `tool <argument>`.\n" }

      it 'leaves content unchanged without warning' do
        expect(log_warn).not_to receive(:call)

        expect(repair).to eq(content)
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

  describe '.check_duo_instructions_fences' do
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

          expect { sync.check_duo_instructions_fences }.to output(/Stale: qa/).to_stderr
        end
      end
    end

    context 'with --warn-stale' do
      context 'when a fence is only stale' do
        let(:stale) { ['qa'] }

        it 'warns without failing the guard', :aggregate_failures do
          expect(sync).not_to receive(:exit)

          expect { sync.check_duo_instructions_fences(warn_stale: true) }
            .to output(/stale on this ref: qa.*No action needed/m).to_stderr
        end
      end

      context 'when a fence is malformed' do
        let(:malformed) { ['qa'] }

        it 'still fails the guard regardless of the flag' do
          expect(sync).to receive(:exit).with(1)

          expect { sync.check_duo_instructions_fences(warn_stale: true) }.to output(/Malformed: qa/).to_stderr
        end
      end

      context 'when a fence is orphaned' do
        let(:orphaned) { ['qa'] }

        it 'still fails the guard regardless of the flag' do
          expect(sync).to receive(:exit).with(1)

          expect { sync.check_duo_instructions_fences(warn_stale: true) }.to output(/Orphaned: qa/).to_stderr
        end
      end
    end
  end

  describe '.reconcile_duo_instructions_fences' do
    before do
      allow(sync).to receive(:banner)
      allow(sync.manifest).to receive(:load)
    end

    context 'with --push' do
      before do
        allow(sync.manifest).to receive(:auto_mr_config)
          .and_return({ 'branch_prefix' => 'docs-sync/principles' })
      end

      # The projection is deferred to the freshly cut branch inside create_reconcile_mr_from_working_tree (which
      # receives the manifest to regenerate against the branch's base), so reconcile_duo_instructions_fences must NOT
      # regenerate on the pipeline-SHA working tree first.
      it 'defers regeneration to the fresh branch and opens the MR', :aggregate_failures do
        expect(sync.manifest).not_to receive(:generate_duo_review_instructions)
        expect(sync).to receive(:create_reconcile_mr_from_working_tree)
          .with({ 'branch_prefix' => 'docs-sync/principles' }, sync.manifest)

        sync.reconcile_duo_instructions_fences(push: true)
      end
    end

    context 'without --push' do
      context 'when the fences are already up to date' do
        before do
          allow(sync.manifest).to receive(:generate_duo_review_instructions).and_return(false)
        end

        it 'does not open an MR' do
          expect(sync).not_to receive(:create_reconcile_mr_from_working_tree)

          expect { sync.reconcile_duo_instructions_fences(push: false) }
            .to output(/already up to date/).to_stdout
        end
      end

      context 'when the fences changed' do
        before do
          allow(sync.manifest).to receive(:generate_duo_review_instructions).and_return(true)
        end

        it 'only rewrites on disk (never re-distilling)' do
          expect(sync).not_to receive(:create_reconcile_mr_from_working_tree)

          expect { sync.reconcile_duo_instructions_fences(push: false) }
            .to output(/\[LOCAL\].*Pass --push/m).to_stdout
        end
      end
    end
  end
end
