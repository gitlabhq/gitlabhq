# frozen_string_literal: true

require 'spec_helper'
require_relative '../../../support/tmpdir'
require_relative '../../../support/abort_capture'
require_relative '../../../../lib/gitlab/principles_distiller/sync'

RSpec.describe Gitlab::PrinciplesDistiller::Sync::Validator do
  include TmpdirHelper
  include AbortCaptureHelper

  let(:tmpdir) { mktmpdir }
  let(:validator) { described_class.new }
  let(:manifest_dir) { File.join(tmpdir, '.ai', 'principles') }
  let(:doc_dir) { File.join(tmpdir, 'doc') }

  let(:manifest_yaml) do
    <<~YAML
      principles:
        backend:
          owner_team: '@gitlab-org/maintainers/rails-backend'
          sources:
            - path: doc/present.md
            - path: doc/renamed.md
    YAML
  end

  before do
    Gitlab::PrinciplesDistiller::Workspace.path = tmpdir
    FileUtils.mkdir_p(manifest_dir)
    FileUtils.mkdir_p(doc_dir)
    File.write(File.join(manifest_dir, 'manifest.yml'), manifest_yaml)
    stub_const('ARGV', [])
  end

  describe '#run' do
    context 'when every referenced SSOT source file exists' do
      before do
        File.write(File.join(doc_dir, 'present.md'), 'content')
        File.write(File.join(doc_dir, 'renamed.md'), 'content')
      end

      it 'does not abort' do
        expect { validator.run }.not_to raise_error
      end

      it 'reports success' do
        expect { validator.run }.to output(/reference existing SSOT source files/).to_stdout
      end
    end

    context 'when a referenced SSOT source file is missing' do
      before do
        File.write(File.join(doc_dir, 'present.md'), 'content')
      end

      it 'aborts, listing the missing path but not the existing one' do
        expect { validator.run }
          .to raise_error(SystemExit)
          .and output(%r{doc/renamed\.md}).to_stderr
          .and output(%r{\A(?!.*doc/present\.md).*\z}m).to_stderr
      end
    end

    context 'when a referenced doc was converted to a directory with an _index.md' do
      before do
        File.write(File.join(doc_dir, 'present.md'), 'content')
        FileUtils.mkdir_p(File.join(doc_dir, 'renamed'))
        File.write(File.join(doc_dir, 'renamed', '_index.md'), 'content')
      end

      it 'resolves via the _index.md fallback and does not abort' do
        expect { validator.run }.not_to raise_error
      end
    end

    context 'when a static_entries path is missing' do
      let(:manifest_yaml) do
        <<~YAML
          static_entries:
            - description: Code style
              path: .ai/missing-static.md
          principles:
            backend:
              owner_team: '@gitlab-org/maintainers/rails-backend'
              sources:
                - path: doc/present.md
        YAML
      end

      before do
        File.write(File.join(doc_dir, 'present.md'), 'content')
      end

      it 'aborts, naming the missing static entry' do
        expect { validator.run }
          .to raise_error(SystemExit)
          .and output(%r{\.ai/missing-static\.md}).to_stderr
      end
    end

    context 'when the distillation prompt exceeds the AI Catalog budget' do
      before do
        File.write(File.join(doc_dir, 'present.md'), 'content')
        File.write(File.join(doc_dir, 'renamed.md'), 'content')
        # Under the YAML limit on its own, but over it once the catalog stores the prompt twice.
        File.write(File.join(manifest_dir, 'distillation_prompt.md'), "#{'word ' * 8_000}\n")
      end

      it 'aborts' do
        expect { validator.run }.to raise_error(SystemExit)
      end

      it 'reports the overage, the duplicate-storage cause, and the upstream fix' do
        message = capture_abort_stderr { validator.run }

        expect(message).to match(/over the AI Catalog limit/)
        expect(message).to match(/counted twice/)
        expect(message).to match(/591638/)
      end
    end

    context 'when the distillation prompt is within budget' do
      before do
        File.write(File.join(doc_dir, 'present.md'), 'content')
        File.write(File.join(doc_dir, 'renamed.md'), 'content')
        File.write(File.join(manifest_dir, 'distillation_prompt.md'), "You are the distiller.\n")
      end

      it 'does not abort' do
        expect { validator.run }.not_to raise_error
      end
    end

    describe 'misplaced baseline rules' do
      let(:manifest_yaml) do
        <<~YAML
          principles:
            backend:
              owner_team: '@gitlab-org/maintainers/rails-backend'
              baseline: .ai/principles/baselines/backend.md
              sources:
                - path: doc/present.md
        YAML
      end

      let(:baseline_content) do
        <<~MARKDOWN
          ## Checklist

          ### Handler Registration

          - Export new test helpers from `test_helpers.js` so they are
            available globally in all tests.
        MARKDOWN
      end

      before do
        File.write(File.join(doc_dir, 'present.md'), 'content')
        FileUtils.mkdir_p(File.join(manifest_dir, 'baselines'))
        FileUtils.mkdir_p(File.join(manifest_dir, 'distilled'))
        File.write(File.join(manifest_dir, 'baselines', 'backend.md'), baseline_content)
        File.write(File.join(manifest_dir, 'distilled', 'backend.md'), distilled_content)
      end

      context 'when a baseline rule sits under a different heading in the distilled file' do
        let(:distilled_content) do
          <<~MARKDOWN
            ## Checklist

            ### Directory Structure

            - Export new test helpers from `test_helpers.js` so they are available globally in all tests.
          MARKDOWN
        end

        it 'aborts' do
          expect { validator.run }.to raise_error(SystemExit)
        end

        it 'names the principle, both headings, and the move-not-delete remedy' do
          message = capture_abort_stderr { validator.run }

          expect(message).to match(/backend/)
          expect(message).to match(/### Handler Registration/)
          expect(message).to match(/### Directory Structure/)
          expect(message).to match(/MOVE/)
          expect(message).to match(/616111/)
        end
      end

      context 'when the rule sits under the same heading as the baseline' do
        let(:distilled_content) do
          <<~MARKDOWN
            ## Checklist

            ### Handler Registration

            - Export new test helpers from `test_helpers.js` so they are available globally in all tests.
          MARKDOWN
        end

        it 'does not abort' do
          expect { validator.run }.not_to raise_error
        end
      end

      context 'when the distilled file carries YAML front matter' do
        let(:distilled_content) do
          <<~MARKDOWN
            ---
            source_checksum: f8153b4aad87d4cb
            distilled_at_sha: 403f0ba78983ea28f47a927139b91425bb93dcef
            ---
            <!-- Auto-generated — do not edit manually -->

            ## Checklist

            ### Handler Registration

            - Export new test helpers from `test_helpers.js` so they are available globally in all tests.
          MARKDOWN
        end

        it 'does not abort' do
          expect { validator.run }.not_to raise_error
        end

        # Front matter is stripped before comparison rather than relying on `logical_units` mapping its lines to an
        # unattributed section, so the comparison does not depend on the front-matter format.
        it 'compares rule placement against content with the front matter removed' do
          received = []

          allow(Gitlab::PrinciplesDistiller::Sync::BaselineRules)
            .to receive(:units_by_section)
            .and_wrap_original do |original, text|
              received << text
              original.call(text)
            end

          validator.run

          expect(received).to include(a_string_matching(/\A## Checklist/))
          expect(received).not_to include(a_string_matching(/source_checksum/))
        end
      end

      context 'when the rule sits under the baseline heading but is duplicated elsewhere' do
        let(:distilled_content) do
          <<~MARKDOWN
            ## Checklist

            ### Handler Registration

            - Export new test helpers from `test_helpers.js` so they are available globally in all tests.

            ### Directory Structure

            - Export new test helpers from `test_helpers.js` so they are available globally in all tests.
          MARKDOWN
        end

        it 'aborts, naming the unexpected heading' do
          message = capture_abort_stderr { validator.run }

          expect(message).to match(/### Directory Structure/)
        end
      end

      context 'when the rule sits outside any heading' do
        let(:distilled_content) do
          <<~MARKDOWN
            - Export new test helpers from `test_helpers.js` so they are available globally in all tests.
          MARKDOWN
        end

        it 'aborts rather than treating the rule as absent' do
          message = capture_abort_stderr { validator.run }

          expect(message).to match(/\(no heading\)/)
        end
      end

      context 'when a baseline rule is absent from the distilled file' do
        let(:distilled_content) do
          <<~MARKDOWN
            ## Checklist

            ### Handler Registration

            - Some unrelated rule.
          MARKDOWN
        end

        it 'does not abort' do
          expect { validator.run }.not_to raise_error
        end
      end

      context 'when the distilled file does not exist yet' do
        let(:distilled_content) { nil }

        before do
          FileUtils.rm_f(File.join(manifest_dir, 'distilled', 'backend.md'))
        end

        it 'does not abort' do
          expect { validator.run }.not_to raise_error
        end
      end
    end

    context 'when a principle is misconfigured (missing owner_team)' do
      let(:manifest_yaml) do
        <<~YAML
          principles:
            backend:
              sources:
                - path: doc/missing.md
        YAML
      end

      it 'aborts during manifest.load validation before the source-existence check' do
        expect { validator.run }
          .to raise_error(SystemExit)
          .and output(/owner_team/).to_stderr
      end
    end
  end
end
