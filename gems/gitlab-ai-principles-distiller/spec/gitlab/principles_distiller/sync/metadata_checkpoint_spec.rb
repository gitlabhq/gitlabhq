# frozen_string_literal: true

require 'spec_helper'
require_relative '../../../../lib/gitlab/principles_distiller/sync'

RSpec.describe Gitlab::PrinciplesDistiller::Sync::MetadataCheckpoint do
  let(:body) { "<!-- Auto-generated -->\n\n# QA Principles\n\n---\n\n## Checklist\n\n- Keep me\n" }
  let(:original) { "---\nsource_checksum: old\ndistilled_at_sha: #{'1' * 40}\n---\n#{body}" }
  let(:checkpoint) do
    described_class.new(
      source_checksum: 'new', distilled_at_sha: '2' * 40, original_sha256: described_class.fingerprint(original)
    )
  end

  describe '#apply' do
    subject(:applied) { checkpoint.apply(content) }

    let(:content) { original }

    it 'replaces only the frontmatter values and preserves the body byte-for-byte' do
      expect(applied).to eq("---\nsource_checksum: new\ndistilled_at_sha: #{'2' * 40}\n---\n#{body}")
    end

    # A merged team MR or a newer metadata update changed the file after this run evaluated it.
    context 'when the file differs from the evaluated one' do
      let(:content) { original.sub('Keep me', 'Changed') }

      it { is_expected.to be_nil }
    end

    context 'when the evaluated file has no distilled_at_sha' do
      let(:original) { "---\nsource_checksum: old\n---\n#{body}" }

      it 'adds it' do
        expect(applied).to eq("---\nsource_checksum: new\ndistilled_at_sha: #{'2' * 40}\n---\n#{body}")
      end
    end

    context 'when the evaluated file has no frontmatter' do
      let(:original) { body }

      it { is_expected.to be_nil }
    end
  end

  describe '.from_h' do
    it 'round-trips through a JSON-parsed hash' do
      expect(described_class.from_h(JSON.parse(JSON.generate(checkpoint.to_h)))).to eq(checkpoint)
    end
  end
end
