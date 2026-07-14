# frozen_string_literal: true

require 'spec_helper'
require 'yaml'
require_relative '../../../../lib/gitlab/principles_distiller/sync/duo_instructions'

RSpec.describe Gitlab::PrinciplesDistiller::Sync::DuoInstructions do
  # A minimal but representative file: a hand-authored group, one generated
  # region, and a trailing hand-authored group, so tests can prove the
  # generator only touches the fenced region.
  let(:fixture) do
    <<~YAML
      instructions:
        - name: Hand authored
          fileFilters:
            - "**/*.rb"
          instructions: |
            1. Keep this group untouched.

        # >>> generated: documentation — gitlab-ai-principles-distiller (from .ai/principles/manifest.yml; do not edit)
        # distilled_at_sha: oldsha111
        # source_checksum: oldsum11
        - name: Documentation
          fileFilters:
            - "doc/**/*.md"
          instructions: |
            Stale body to be replaced.
        # <<< end generated: documentation

        - name: Trailing group
          fileFilters:
            - "**/*.js"
          instructions: |
            1. Also untouched.
    YAML
  end

  let(:distilled_body) do
    <<~BODY.rstrip
      ### Voice and Tone

      - Write in US English.
      - Use active voice.

      ### Capitalization

      - Use sentence case for topic titles.
    BODY
  end

  let(:fences) do
    {
      'documentation' => {
        name: 'Documentation',
        file_filters: ['doc/**/*.md'],
        distilled_body: distilled_body,
        distilled_at_sha: 'newsha222',
        source_checksum: 'newsum22',
        references: [
          'doc/development/documentation/styleguide/_index.md',
          'doc/development/documentation/styleguide/word_list.md'
        ]
      }
    }
  end

  describe '.fenced_principles' do
    it 'returns the principle keys with generated regions in document order' do
      extra = <<~EXTRA.gsub(/^/, '  ')
        # >>> generated: documentation-api — gitlab-ai-principles-distiller (from .ai/principles/manifest.yml; do not edit)
        # distilled_at_sha: x
        # source_checksum: y
        - name: API documentation
          fileFilters:
            - "doc/api/**/*.md"
          instructions: |
            body
        # <<< end generated: documentation-api
      EXTRA

      expect(described_class.fenced_principles(fixture + extra)).to eq(%w[documentation documentation-api])
    end

    it 'returns an empty array when no regions exist' do
      expect(described_class.fenced_principles('instructions: []')).to eq([])
    end
  end

  describe '.regenerate' do
    subject(:regenerated) { described_class.regenerate(yaml, fences: regenerate_fences) }

    # Defaults; inner contexts override `yaml` and/or `regenerate_fences`.
    let(:yaml) { fixture }
    let(:regenerate_fences) { fences }

    it 'refreshes the distilled_at_sha and source_checksum directives' do
      expect(regenerated).to include('  # distilled_at_sha: newsha222')
      expect(regenerated).to include('  # source_checksum: newsum22')
      expect(regenerated).not_to include('oldsha111')
      expect(regenerated).not_to include('oldsum11')
    end

    it 'preserves the hand-authored name and fileFilters' do
      expect(regenerated).to include("  - name: Documentation\n    fileFilters:\n      - \"doc/**/*.md\"")
    end

    it 'replaces the body with the distilled checklist sections' do
      expect(regenerated).to include('      ### Voice and Tone')
      expect(regenerated).to include('      - Write in US English.')
      expect(regenerated).to include('      ### Capitalization')
      expect(regenerated).not_to include('Stale body to be replaced.')
    end

    it 'starts the body directly with the distilled checklist, with no intro preamble' do
      expect(regenerated).to include("    instructions: |\n      ### Voice and Tone")
      expect(regenerated).not_to include('Sourced from the distilled')
      expect(regenerated).not_to include('Treat as guidance')
    end

    it 'appends a Reference line (repo-relative path) for every injected source' do
      expect(regenerated).to include(
        '      - Reference: doc/development/documentation/styleguide/_index.md'
      )
      expect(regenerated).to include(
        '      - Reference: doc/development/documentation/styleguide/word_list.md'
      )
    end

    it 'leaves hand-authored groups outside the region untouched' do
      expect(regenerated).to include('1. Keep this group untouched.')
      expect(regenerated).to include('1. Also untouched.')
      expect(regenerated).to include('  - name: Trailing group')
    end

    it 'produces valid YAML' do
      expect { YAML.safe_load(regenerated) }.not_to raise_error
    end

    it 'is idempotent' do
      once = described_class.regenerate(fixture, fences: fences)
      twice = described_class.regenerate(once, fences: fences)
      expect(twice).to eq(once)
    end

    context 'when the fence carries a "# fileFilters:" override directive' do
      let(:yaml) do
        fixture.sub(
          "    fileFilters:\n      - \"doc/**/*.md\"",
          "    fileFilters:\n      - \"doc/api/**/*.md\""
        )
      end

      it 'preserves the override' do
        expect(regenerated).to include("      - \"doc/api/**/*.md\"")
        expect(regenerated).not_to include("      - \"doc/**/*.md\"")
      end
    end

    context 'when a fenced principle is absent from the fences data' do
      let(:regenerate_fences) { {} }

      it 'leaves that region untouched' do
        expect(regenerated).to eq(fixture)
      end
    end

    context 'with an empty distilled body' do
      let(:regenerate_fences) do
        fences.transform_values { |data| data.merge(distilled_body: "   \n") }
      end

      it 'raises rather than emitting an empty instructions body' do
        expect { regenerated }.to raise_error(/empty instructions body for 'documentation'/)
      end
    end

    context 'with whitespace-only body lines' do
      let(:regenerate_fences) do
        fences.transform_values do |data|
          data.merge(distilled_body: "### Section\n   \n- A bullet.")
        end
      end

      it 'does not emit trailing whitespace' do
        expect(regenerated).not_to match(/^ +$/)
      end
    end
  end

  describe '.check' do
    subject(:checked) { described_class.check(yaml, fences: check_fences, seeded: seeded) }

    # Defaults; inner contexts override `yaml`, `check_fences`, and/or `seeded`.
    let(:yaml) { fixture }
    let(:check_fences) { fences }
    let(:seeded) { ['documentation'] }

    context 'when the recorded directives are stale' do
      it 'groups the principle under stale and marks it failing' do
        expect(checked.stale).to eq(['documentation'])
        expect(checked.failing).to eq(['documentation'])
        expect(checked.pending).to be_empty
        expect(checked).not_to be_clean
      end
    end

    context 'when the recorded directives match' do
      let(:check_fences) do
        fences.transform_values do |data|
          data.merge(distilled_at_sha: 'oldsha111', source_checksum: 'oldsum11')
        end
      end

      it 'is clean with no failing or pending fences' do
        expect(checked.failing).to eq([])
        expect(checked.pending).to eq([])
        expect(checked).to be_clean
      end
    end

    context 'when only the checksum differs' do
      let(:check_fences) do
        fences.transform_values do |data|
          data.merge(distilled_at_sha: 'oldsha111', source_checksum: 'different')
        end
      end

      it 'detects the staleness' do
        expect(checked.stale).to eq(['documentation'])
        expect(checked.failing).to eq(['documentation'])
      end
    end

    context 'when a fence has a manifest entry but no distilled file yet' do
      let(:check_fences) { {} }
      let(:seeded) { ['documentation'] }

      # The documented seed-then-distill state: a fence is added before its
      # first distillation. build_duo_fences omits it (no distilled file), but
      # because it has a manifest entry the guard must treat it as a pending
      # seed (warn) rather than a failing orphan.
      it 'classifies the fence as pending and does not fail' do
        expect(checked.pending).to eq(['documentation'])
        expect(checked.orphaned).to be_empty
        expect(checked.failing).to eq([])
        expect(checked).not_to be_clean
      end
    end

    context 'when a fence has neither a distilled file nor a manifest entry' do
      let(:check_fences) { {} }
      let(:seeded) { [] }

      # Truly orphaned: no source of truth and no manifest entry that would
      # produce one. The guard must fail.
      it 'classifies the fence as orphaned and fails' do
        expect(checked.orphaned).to eq(['documentation'])
        expect(checked.pending).to be_empty
        expect(checked.failing).to eq(['documentation'])
      end
    end

    context 'when seeded is nil (no manifest context supplied)' do
      let(:check_fences) { {} }
      let(:seeded) { nil }

      # Backwards-compatible fallback: without manifest context every fence
      # lacking a distilled file is treated as orphaned.
      it 'treats a fence with no distilled file as orphaned' do
        expect(checked.orphaned).to eq(['documentation'])
        expect(checked.pending).to be_empty
        expect(checked.failing).to eq(['documentation'])
      end
    end

    context 'when a region has a BEGIN marker but no matching END' do
      let(:yaml) { fixture.sub(/^  # <<< end generated: documentation$/, '  - name: Orphaned') }
      let(:check_fences) do
        fences.transform_values do |data|
          data.merge(distilled_at_sha: 'oldsha111', source_checksum: 'oldsum11')
        end
      end

      it 'flags the principle as malformed even when directives would otherwise match' do
        expect(checked.malformed).to eq(['documentation'])
        expect(checked.failing).to eq(['documentation'])
      end
    end

    context 'when the same principle has duplicate BEGIN markers' do
      # Two BEGINs for `documentation` but the first END removed: the
      # non-greedy REGION_PATTERN backref collapses both into one match, so
      # the begin count (2) exceeds the region count (1).
      let(:yaml) do
        extra = <<~EXTRA.gsub(/^/, '  ')
          # >>> generated: documentation — gitlab-ai-principles-distiller (from .ai/principles/manifest.yml; do not edit)
          # distilled_at_sha: oldsha111
          # source_checksum: oldsum11
          - name: Documentation duplicate
            fileFilters:
              - "doc/**/*.md"
            instructions: |
              another body
          # <<< end generated: documentation
        EXTRA
        fixture.sub(/^  # <<< end generated: documentation$\n/, '') + extra
      end

      let(:check_fences) do
        fences.transform_values do |data|
          data.merge(distilled_at_sha: 'oldsha111', source_checksum: 'oldsum11')
        end
      end

      it 'flags the duplicated principle as malformed' do
        expect(checked.malformed).to eq(['documentation'])
        expect(checked.failing).to eq(['documentation'])
      end
    end
  end

  describe '.malformed_principles' do
    subject(:malformed) { described_class.malformed_principles(yaml) }

    let(:yaml) { fixture }

    context 'when every BEGIN pairs with one region' do
      it 'returns an empty array' do
        expect(malformed).to eq([])
      end
    end

    context 'when an END marker is missing' do
      let(:yaml) { fixture.sub(/^  # <<< end generated: documentation$/, '  - name: Orphaned') }

      it 'flags the principle' do
        expect(malformed).to eq(['documentation'])
      end
    end

    context 'when a principle has duplicate BEGIN markers' do
      # A second BEGIN for the same key without its own END: the begin count
      # (2) exceeds the number of whole regions REGION_PATTERN pairs (1).
      let(:yaml) { "#{fixture}  # >>> generated: documentation #{described_class::BEGIN_SUFFIX}\n" }

      it 'flags the principle' do
        expect(malformed).to eq(['documentation'])
      end
    end
  end
end
