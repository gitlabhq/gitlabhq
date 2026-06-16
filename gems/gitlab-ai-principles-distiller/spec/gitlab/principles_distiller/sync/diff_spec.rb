# frozen_string_literal: true

require 'spec_helper'
require_relative '../../../../lib/gitlab/principles_distiller/sync/diff'

RSpec.describe Gitlab::PrinciplesDistiller::Sync::Diff do
  describe '.strip_preamble' do
    subject(:strip_preamble) { described_class.strip_preamble(content) }

    context 'with content before the first heading' do
      let(:content) { "Some preamble\nMore text\n# Title\n\nBody" }

      it { is_expected.to eq("# Title\n\nBody\n") }
    end

    context 'with trailing ## Output Format sentinel' do
      let(:content) { "# Title\n\n- Item 1\n\n## Output Format" }

      it { is_expected.to eq("# Title\n\n- Item 1\n") }
    end

    context 'with ## Output Format and trailing whitespace' do
      let(:content) { "# Title\n\n- Item 1\n\n## Output Format  \n" }

      it { is_expected.to eq("# Title\n\n- Item 1\n") }
    end

    context 'without trailing newline' do
      let(:content) { "# Title\n\n- Item 1" }

      it { is_expected.to end_with("\n") }
    end

    context 'without preamble' do
      let(:content) { "# Title\n\nBody" }

      it { is_expected.to eq("# Title\n\nBody\n") }
    end
  end

  describe '.reduce_noise' do
    subject(:result) { described_class.reduce_noise(old_content, new_content) }

    context 'when new line is a close rephrase' do
      let(:old_content) { "### Section A\n\n- Query changes validated for performance at GitLab.com scale\n" }
      let(:new_content) { "### Section A\n\n- Query changes must be validated for performance at GitLab.com scale\n" }

      it 'keeps old wording', :aggregate_failures do
        expect(result).to include('- Query changes validated for performance at GitLab.com scale')
        expect(result).not_to include('must be')
      end
    end

    context 'when new line is substantially different' do
      let(:old_content) { "### Section A\n\n- Use foo\n" }
      let(:new_content) { "### Section A\n\n- Completely different rule about bar\n" }

      it 'keeps new wording' do
        expect(result).to include('- Completely different rule about bar')
      end
    end

    context 'when new lines are added' do
      let(:old_content) { "### Section A\n\n- Existing rule\n" }
      let(:new_content) { "### Section A\n\n- Existing rule\n- Brand new rule\n" }

      it 'preserves genuinely new lines', :aggregate_failures do
        expect(result).to include('- Existing rule')
        expect(result).to include('- Brand new rule')
      end
    end

    context 'when new sections are added' do
      let(:old_content) { "### Section A\n\n- Item 1\n" }
      let(:new_content) { "### Section A\n\n- Item 1\n\n### Section B\n\n- New item\n" }

      it 'keeps new sections entirely', :aggregate_failures do
        expect(result).to include('### Section B')
        expect(result).to include('- New item')
      end
    end

    context 'when a new top-level (##) section is added' do
      let(:old_content) { "## Checklist\n\n### Section A\n\n- Item 1\n" }
      let(:new_content) { "## Checklist\n\n### Section A\n\n- Item 1\n\n## New Topic\n\n- Brand new rule\n" }

      it 'keeps the new ## section and its content', :aggregate_failures do
        expect(result).to include('## New Topic')
        expect(result).to include('- Brand new rule')
        expect(result).to include('- Item 1')
      end
    end

    context 'when sections are removed' do
      let(:old_content) { "### Section A\n\n- Item 1\n\n### Section B\n\n- Item 2\n" }
      let(:new_content) { "### Section A\n\n- Item 1\n" }

      it 'drops sections removed by Duo', :aggregate_failures do
        expect(result).not_to include('### Section B')
        expect(result).not_to include('- Item 2')
      end
    end
  end

  describe '.meaningful?' do
    subject(:meaningful_diff) { described_class.meaningful?(current, updated) }

    context 'when current is nil (new file)' do
      let(:current) { nil }
      let(:updated) { 'content' }

      it { is_expected.to be true }
    end

    context 'when updated is nil (distillation failure)' do
      let(:current) { 'content' }
      let(:updated) { nil }

      it { is_expected.to be false }
    end

    context 'when both are nil' do
      let(:current) { nil }
      let(:updated) { nil }

      it { is_expected.to be false }
    end

    context 'with whitespace-only differences' do
      let(:current) { "- Item 1\n\n" }
      let(:updated) { "- Item 1\n" }

      it { is_expected.to be false }
    end

    context 'with different content' do
      let(:current) { "- Item 1\n" }
      let(:updated) { "- Item 2\n" }

      it { is_expected.to be true }
    end
  end

  describe '.parse_sections (private helper)' do
    subject(:sections) { described_class.send(:parse_sections, content) }

    context 'with ## and ### headings' do
      let(:content) { "# Title\n\n## Checklist\n\n### Section A\n\n- Item 1\n\n### Section B\n\n- Item 2\n" }

      it 'splits content by both ## and ### headings', :aggregate_failures do
        expect(sections.keys).to eq([nil, '## Checklist', '### Section A', '### Section B'])
        expect(sections['### Section A']).to include('- Item 1')
        expect(sections['### Section B']).to include('- Item 2')
      end
    end

    context 'with a new top-level ## section after subsections' do
      let(:content) { "## Checklist\n\n### Section A\n\n- Item 1\n\n## Feature flag events\n\n- New rule\n" }

      it 'splits the new ## section into its own key', :aggregate_failures do
        expect(sections.keys).to include('## Feature flag events')
        expect(sections['## Feature flag events']).to include('- New rule')
      end
    end

    context 'with preamble before first heading' do
      let(:content) { "# Title\n\n### Section\n\n- Item" }

      it 'puts preamble under nil key' do
        expect(sections[nil]).to eq(['# Title', ''])
      end
    end
  end

  describe '.word_similarity (private helper)' do
    subject(:similarity) { described_class.send(:word_similarity, line_a, line_b) }

    context 'with identical lines' do
      let(:line_a) { '- Use foo bar' }
      let(:line_b) { '- Use foo bar' }

      it { is_expected.to eq(1.0) }
    end

    context 'with completely different lines' do
      let(:line_a) { '- Alpha beta' }
      let(:line_b) { '- Gamma delta' }

      it { is_expected.to eq(0.0) }
    end

    context 'with two empty strings' do
      let(:line_a) { '' }
      let(:line_b) { '' }

      it { is_expected.to eq(0.0) }
    end

    context 'with partially overlapping words' do
      let(:line_a) { '- Use foo bar' }
      let(:line_b) { '- Use foo baz' }

      it 'calculates Jaccard similarity on word sets' do
        # words: [use, foo, bar] vs [use, foo, baz] => intersection=2, union=4 => 0.5
        expect(similarity).to eq(0.5)
      end
    end

    context 'with punctuation and case differences' do
      let(:line_a) { '- Use `Gitlab::SafeRequestStore` for memoization' }
      let(:line_b) { '- use gitlabsaferequeststore for memoization' }

      it { is_expected.to eq(1.0) }
    end
  end

  describe '.find_best_match (private helper)' do
    subject(:best_match) { described_class.send(:find_best_match, line, candidates) }

    context 'with matching candidates' do
      let(:line) { '- Use foo baz' }
      let(:candidates) { ['- Use foo bar', '- Completely different'] }

      it 'returns the best matching candidate and score', :aggregate_failures do
        match, score = best_match

        expect(match).to eq('- Use foo bar')
        expect(score).to be >= 0.5
      end
    end

    context 'with empty candidates' do
      let(:line) { '- Some line' }
      let(:candidates) { [] }

      it 'returns nil and 0.0', :aggregate_failures do
        match, score = best_match

        expect(match).to be_nil
        expect(score).to eq(0.0)
      end
    end
  end
end
