# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TagsFinder, feature_category: :source_code_management do
  subject(:tags_finder) { described_class.new(repository, params) }

  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:repository) { project.repository }

  let(:params) { {} }

  def load_tags(params, gitaly_pagination: false)
    described_class.new(repository, params).execute(gitaly_pagination: gitaly_pagination)
  end

  describe '#execute' do
    context 'sort only' do
      it 'sorts by name' do
        expect(load_tags({}).first.name).to eq("v1.0.0")
      end

      it 'sorts by recently_updated' do
        recently_updated_tag = repository.tags.max do |a, b|
          repository.commit(a.dereferenced_target).committed_date <=> repository.commit(b.dereferenced_target).committed_date
        end

        params = { sort: 'updated_desc' }

        expect(load_tags(params).first.name).to eq(recently_updated_tag.name)
      end

      it 'sorts by last_updated' do
        params = { sort: 'updated_asc' }

        expect(load_tags(params).first.name).to eq('v1.0.0')
      end

      context 'when sort is not a string' do
        it 'ignores sort parameter' do
          params = { sort: { 'invalid' => 'string' } }

          expect(load_tags(params).first.name).to eq('v1.0.0')
        end
      end
    end

    context 'filter only' do
      it 'filters tags by name' do
        result = load_tags({ search: '1.0.0' })

        expect(result.first.name).to eq('v1.0.0')
        expect(result.count).to eq(1)
      end

      it 'does not find any tags with that name' do
        expect(load_tags({ search: 'hey' }).count).to eq(0)
      end

      it 'filters tags by name that begins with' do
        result = load_tags({ search: '^v1.0' })

        expect(result.first.name).to eq('v1.0.0')
        expect(result.count).to eq(1)
      end

      it 'filters tags by name that ends with' do
        result = load_tags({ search: '0.0$' })

        expect(result.first.name).to eq('v1.0.0')
        expect(result.count).to eq(1)
      end

      it 'filters tags by name with wildcard' do
        result = load_tags({ search: 'v1.*.0' })

        expect(result.first.name).to eq('v1.0.0')
        expect(result.second.name).to eq('v1.1.0')
        expect(result.count).to eq(2)
      end

      it 'filters tags by nonexistent name that begins with' do
        result = load_tags({ search: '^nope' })

        expect(result.count).to eq(0)
      end

      it 'filters tags by nonexistent name that ends with' do
        result = load_tags({ search: 'nope$' })
        expect(result.count).to eq(0)
      end

      it 'filters tags by nonexistent name with wildcard' do
        result = load_tags({ search: 'n*e' })
        expect(result.count).to eq(0)
      end

      it 'uses ::Gitlab::UntrustedRegexp for regex filter' do
        escaped_regex = '^v1\\..*?.*?.*?.*?.*?.*?.*?.*?.*?.*?\\.0$'

        expect(::Gitlab::UntrustedRegexp).to receive(:new).with(escaped_regex).once.and_call_original
        result = load_tags({ search: '^v1.**********.0$' })

        expect(result.count).to eq(2)
      end

      context 'when search is not a string' do
        it 'returns no matches' do
          result = load_tags({ search: { 'a' => 'b' } })
          expect(result.count).to eq(0)
        end
      end
    end

    context 'filter and sort' do
      let(:tags_to_compare) { %w[v1.0.0 v1.1.0] }

      subject { load_tags(params).select { |tag| tags_to_compare.include?(tag.name) } }

      context 'when sort by updated_desc' do
        let(:params) { { sort: 'updated_desc', search: 'v1' } }

        it 'filters tags by name' do
          expect(subject.first.name).to eq('v1.1.0')
          expect(subject.count).to eq(2)
        end
      end

      context 'when sort by updated_asc' do
        let(:params) { { sort: 'updated_asc', search: 'v1' } }

        it 'filters tags by name' do
          expect(subject.first.name).to eq('v1.0.0')
          expect(subject.count).to eq(2)
        end
      end
    end

    context 'with Gitaly pagination' do
      subject { load_tags(params, gitaly_pagination: true) }

      context 'by page_token and per_page' do
        let(:params) { { page_token: 'v1.0.0', per_page: 1 } }

        it 'filters tags' do
          result = subject

          expect(result.map(&:name)).to eq(%w[v1.1.0])
        end
      end

      context 'by next page_token and per_page' do
        let(:params) { { page_token: 'v1.1.0', per_page: 2 } }

        it 'filters branches' do
          result = subject

          expect(result.map(&:name)).to eq(%w[v1.1.1])
        end
      end

      context 'by per_page only' do
        let(:params) { { per_page: 2 } }

        it 'filters branches' do
          result = subject

          expect(result.map(&:name)).to eq(%w[v1.0.0 v1.1.0])
        end

        context 'when per_page is over the limit' do
          let(:params) { { per_page: 3 } }

          before do
            stub_const('Gitlab::PaginationDelegate::MAX_PER_PAGE', 2)
          end

          it 'limits the maximum number of elements' do
            result = subject

            expect(result.map(&:name)).to eq(%w[v1.0.0 v1.1.0])
          end
        end
      end

      context 'by page_token only' do
        let(:params) { { page_token: 'feature' } }

        it 'raises an error' do
          expect do
            subject
          end.to raise_error(Gitlab::Git::InvalidPageToken, 'Invalid page token: refs/tags/feature')
        end
      end

      context 'pagination and sort' do
        context 'by per_page' do
          let(:params) { { sort: 'updated_desc', per_page: 5 } }

          it 'filters branches' do
            result = subject

            expect(result.map(&:name)).to eq(%w[v1.1.1 v1.1.0 v1.0.0])
          end
        end

        context 'by page_token and per_page' do
          let(:params) { { sort: 'updated_desc', page_token: 'v1.1.1', per_page: 2 } }

          it 'filters branches' do
            result = subject

            expect(result.map(&:name)).to eq(%w[v1.1.0 v1.0.0])
          end
        end
      end

      context 'pagination and search' do
        let(:params) { { search: '1.1.1', per_page: 1 } }

        it 'ignores the pagination for search' do
          result = subject

          expect(result.map(&:name)).to eq(%w[v1.1.1])
        end
      end
    end

    context 'when Gitaly is unavailable' do
      it 'raises an exception' do
        expect(Gitlab::GitalyClient).to receive(:call).and_raise(GRPC::Unavailable)

        tags_finder = described_class.new(repository, {})

        expect { tags_finder.execute }.to raise_error(Gitlab::Git::CommandError)
      end
    end
  end

  describe '#next_cursor' do
    subject { tags_finder.next_cursor }

    it 'always nil before #execute call' do
      is_expected.to be_nil
    end

    context 'after #execute' do
      context 'with gitaly pagination' do
        before do
          tags_finder.execute(gitaly_pagination: true)
        end

        context 'without pagination params' do
          it { is_expected.to be_nil }
        end

        context 'with pagination params' do
          let(:params) { { per_page: 5 } }

          it { is_expected.to be_present }

          context 'when all objects can be returned on the same page' do
            let(:params) { { per_page: 100 } }

            it { is_expected.to be_present }
          end
        end
      end

      context 'without gitaly pagination' do
        before do
          tags_finder.execute(gitaly_pagination: false)
        end

        context 'without pagination params' do
          it { is_expected.to be_nil }
        end

        context 'with pagination params' do
          let(:params) { { per_page: 5 } }

          it { is_expected.to be_nil }

          context 'when all objects can be returned on the same page' do
            let(:params) { { per_page: 100 } }

            it { is_expected.to be_nil }
          end
        end
      end
    end
  end
end
