# frozen_string_literal: true

require 'spec_helper'
require_relative '../../../../lib/gitlab/principles_distiller/sync/links'

RSpec.describe Gitlab::PrinciplesDistiller::Sync::Links do
  describe '.absolutize' do
    subject(:absolutize) do
      described_class.absolutize(content, sources: sources, exist: exist, warn_unresolved: warn_unresolved)
    end

    let(:sources) { [{ 'path' => 'doc/development/documentation/experiment_beta.md' }] }
    let(:exist) { ->(_path) { true } }
    let(:warn_unresolved) { nil }

    context 'with a source-relative .md link' do
      let(:content) do
        '- See the [feature summary](../../user/gitlab_duo/feature_summary.md) for details.'
      end

      it 'rewrites it to the canonical docs URL' do
        expect(absolutize).to eq(
          '- See the [feature summary](https://docs.gitlab.com/user/gitlab_duo/feature_summary/) for details.'
        )
      end
    end

    context 'with a relative link to an _index.md page' do
      let(:sources) { [{ 'path' => 'doc/development/documentation/_index.md' }] }
      let(:content) { '[FE guide](../fe_guide/_index.md)' }

      it 'drops the /_index.md suffix' do
        expect(absolutize).to eq('[FE guide](https://docs.gitlab.com/development/fe_guide/)')
      end
    end

    context 'with an anchor fragment' do
      let(:content) { '[curl commands](restful_api_styleguide.md#curl-commands)' }

      it 'preserves the anchor' do
        expect(absolutize).to eq(
          '[curl commands](https://docs.gitlab.com/development/documentation/restful_api_styleguide/#curl-commands)'
        )
      end
    end

    context 'with an already-absolute link' do
      let(:content) { '[docs](https://docs.gitlab.com/user/foo/)' }

      it 'leaves it untouched' do
        expect(absolutize).to eq(content)
      end
    end

    context 'with an in-document anchor link' do
      let(:content) { '[jump](#some-heading)' }

      it 'leaves it untouched' do
        expect(absolutize).to eq(content)
      end
    end

    context 'with a non-markdown relative link' do
      let(:content) { '[script](../../scripts/lint-doc.sh)' }

      it 'leaves it untouched' do
        expect(absolutize).to eq(content)
      end
    end

    context 'with multiple sources' do
      let(:sources) do
        [
          { 'path' => 'doc/development/documentation/experiment_beta.md' },
          { 'path' => 'doc/development/fe_guide/accessibility/_index.md' }
        ]
      end

      let(:content) { '[best practices](best_practices.md)' }
      let(:exist) do
        ->(path) { path == 'doc/development/fe_guide/accessibility/best_practices.md' }
      end

      it 'picks the source directory whose candidate exists' do
        expect(absolutize).to eq(
          '[best practices](https://docs.gitlab.com/development/fe_guide/accessibility/best_practices/)'
        )
      end
    end

    context 'when the candidate does not exist under any source directory' do
      let(:exist) { ->(_path) { false } }
      let(:content) { '[missing](../does/not/exist.md)' }
      let(:warn_unresolved) { instance_double(Proc) }

      it 'leaves the link untouched and reports it' do
        expect(warn_unresolved).to receive(:call).with('../does/not/exist.md')

        expect(absolutize).to eq(content)
      end
    end

    context 'with an ee/doc source' do
      let(:sources) { [{ 'path' => 'ee/doc/foo/bar.md' }] }
      let(:content) { '[baz](baz.md)' }

      it 'maps ee/doc onto the docs site root' do
        expect(absolutize).to eq('[baz](https://docs.gitlab.com/foo/baz/)')
      end
    end

    context 'when a link resolves to a doc-prefix root _index.md' do
      let(:sources) { [{ 'path' => 'doc/_index.md' }] }
      let(:content) { '[docs home](_index.md)' }

      it 'maps it to the bare docs base URL' do
        expect(absolutize).to eq('[docs home](https://docs.gitlab.com/)')
      end
    end

    context 'without an existence predicate' do
      let(:exist) { nil }
      let(:content) { '[feature summary](../../user/gitlab_duo/feature_summary.md)' }

      it 'accepts the first doc-tree candidate' do
        expect(absolutize).to eq('[feature summary](https://docs.gitlab.com/user/gitlab_duo/feature_summary/)')
      end
    end

    context 'with several links in one document' do
      let(:sources) { [{ 'path' => 'doc/development/documentation/styleguide/_index.md' }] }
      let(:content) do
        <<~MD
          - See [word list](word_list.md).
          - Already absolute: [topic types](https://docs.gitlab.com/development/documentation/topic_types/).
          - In-doc anchor: [bold](#bold).
        MD
      end

      it 'rewrites only the relative .md link' do
        expect(absolutize).to eq(<<~MD)
          - See [word list](https://docs.gitlab.com/development/documentation/styleguide/word_list/).
          - Already absolute: [topic types](https://docs.gitlab.com/development/documentation/topic_types/).
          - In-doc anchor: [bold](#bold).
        MD
      end
    end
  end
end
