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

    context 'when a rephrased line changes an inline-code identifier' do
      let(:old_content) do
        "### JSON Parsing\n\n" \
          "- Use `Gitlab::Json.safe_parse` instead of `Gitlab::Json.parse` when handling untrusted input\n"
      end

      let(:new_content) do
        "### JSON Parsing\n\n" \
          "- Use `Gitlab::Json::SafeParser.parse` instead of `Gitlab::Json.parse` when handling untrusted input\n"
      end

      it 'keeps the new wording so the identifier change survives', :aggregate_failures do
        expect(result).to include('`Gitlab::Json::SafeParser.parse`')
        expect(result).not_to include('`Gitlab::Json.safe_parse`')
      end
    end

    context 'when a rephrased line keeps the same inline-code identifier' do
      let(:old_content) { "### Section A\n\n- Query changes validated with `Gitlab::Json.parse` at scale\n" }
      let(:new_content) { "### Section A\n\n- Query changes must be validated with `Gitlab::Json.parse` at scale\n" }

      it 'still collapses to the old wording', :aggregate_failures do
        expect(result).to include('- Query changes validated with `Gitlab::Json.parse` at scale')
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

    context 'when content inside a fenced code block changes' do
      let(:old_content) do
        "### Examples\n\n" \
          "```ruby\n" \
          "data = Gitlab::Json.safe_parse(input)\n" \
          "```\n"
      end

      let(:new_content) do
        "### Examples\n\n" \
          "```ruby\n" \
          "data = Gitlab::Json::SafeParser.parse(input)\n" \
          "```\n"
      end

      it 'keeps the new fenced content verbatim', :aggregate_failures do
        expect(result).to include('data = Gitlab::Json::SafeParser.parse(input)')
        expect(result).not_to include('data = Gitlab::Json.safe_parse(input)')
      end
    end

    context 'when a fenced line resembles a prior checklist line' do
      let(:old_content) { "### A\n\n- run `bundle install` before tests\n" }
      let(:new_content) do
        "### A\n\n- run `bundle install` before tests\n\n" \
          "```shell\n" \
          "run `bundle install` before tests\n" \
          "```\n"
      end

      it 'does not collapse the fenced line into the prose bullet', :aggregate_failures do
        expect(result).to include("```shell")
        expect(result.scan('run `bundle install` before tests').size).to eq(2)
      end
    end

    context 'when a rephrased line uses a multi-backtick code span' do
      let(:old_content) { "### A\n\n- Use ``code with ` backtick`` for the old name\n" }
      let(:new_content) { "### A\n\n- Use ``code with ` backtick`` for the renamed thing\n" }

      it 'keeps the new wording rather than risk a wrong collapse' do
        expect(result).to include('for the renamed thing')
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

  describe '.same_code_tokens? (private helper)' do
    subject(:same) { described_class.send(:same_code_tokens?, line_a, line_b) }

    context 'with identical inline-code spans in different order' do
      let(:line_a) { 'Use `foo` then `bar`' }
      let(:line_b) { 'Prefer `bar` over `foo` here' }

      it { is_expected.to be true }
    end

    context 'with a changed inline-code span' do
      let(:line_a) { 'Use `Gitlab::Json.safe_parse` here' }
      let(:line_b) { 'Use `Gitlab::Json::SafeParser.parse` here' }

      it { is_expected.to be false }
    end

    context 'with no inline-code spans on either line' do
      let(:line_a) { 'plain prose one' }
      let(:line_b) { 'plain prose two' }

      it { is_expected.to be true }
    end

    context 'when a line uses a multi-backtick span (unfingerprintable)' do
      let(:line_a) { 'Use ``a ` b`` here' }
      let(:line_b) { 'Use ``a ` b`` here' }

      it 'is not provably equal, so returns false' do
        expect(same).to be false
      end
    end

    context 'when a line has an odd number of backticks' do
      let(:line_a) { 'Use `foo here' }
      let(:line_b) { 'Use `foo here' }

      it { is_expected.to be false }
    end
  end

  describe '.fence_delimiter? (private helper)' do
    subject(:fence) { described_class.send(:fence_delimiter?, line) }

    context 'with an opening fence and info string' do
      let(:line) { '```ruby' }

      it { is_expected.to be true }
    end

    context 'with an indented closing fence' do
      let(:line) { '  ```' }

      it { is_expected.to be true }
    end

    context 'with a tilde fence' do
      let(:line) { '~~~' }

      it { is_expected.to be true }
    end

    context 'with a normal bullet containing inline code' do
      let(:line) { '- Use `Foo` here' }

      it { is_expected.to be false }
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
