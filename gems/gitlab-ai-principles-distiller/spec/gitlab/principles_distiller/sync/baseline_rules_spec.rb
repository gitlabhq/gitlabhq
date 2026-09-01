# frozen_string_literal: true

require 'spec_helper'
require_relative '../../../../lib/gitlab/principles_distiller/sync/baseline_rules'

RSpec.describe Gitlab::PrinciplesDistiller::Sync::BaselineRules do
  describe '.units_by_section' do
    subject(:sections) { described_class.units_by_section(text) }

    context 'with rules under headings' do
      let(:text) do
        <<~MARKDOWN
          ## Checklist

          ### Directory Structure

          - Place files under `spec/`.

          ### Handler Registration

          - Register handlers in `handlers.js`.
        MARKDOWN
      end

      it 'maps each rule to the heading it appears under' do
        expect(sections).to eq(
          'Place files under `spec/`' => ['### Directory Structure'],
          'Register handlers in `handlers.js`' => ['### Handler Registration']
        )
      end
    end

    context 'when a rule is hard-wrapped across lines' do
      let(:text) do
        <<~MARKDOWN
          ### Handler Registration

          - Export new test helpers from `test_helpers.js` so they are
            available globally in all tests.
        MARKDOWN
      end

      it 'joins the continuation lines into a single unit' do
        expect(sections).to eq(
          'Export new test helpers from `test_helpers.js` so they are available globally in all tests' =>
            ['### Handler Registration']
        )
      end
    end

    context 'when the same rule appears under two headings' do
      let(:text) do
        <<~MARKDOWN
          ### First

          - Shared rule.

          ### Second

          - Shared rule.
        MARKDOWN
      end

      it 'records both occurrences in document order' do
        expect(sections).to eq('Shared rule' => ['### First', '### Second'])
      end
    end

    context 'when a rule precedes any heading' do
      let(:text) { "- Rule with no heading.\n" }

      it 'records it under a nil heading' do
        expect(sections).to eq('Rule with no heading' => [nil])
      end
    end

    context 'with thematic breaks and blank lines' do
      let(:text) do
        <<~MARKDOWN
          ### Section

          - First rule.

          ---

          - Second rule.
        MARKDOWN
      end

      it 'treats them as unit boundaries and excludes them' do
        expect(sections).to eq(
          'First rule' => ['### Section'],
          'Second rule' => ['### Section']
        )
      end
    end
  end
end
