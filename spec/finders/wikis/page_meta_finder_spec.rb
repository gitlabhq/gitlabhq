# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Wikis::PageMetaFinder, feature_category: :wiki do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project) }
  let_it_be(:wiki_page_meta_1) { create(:wiki_page_meta, title: 'Deploy Guide', project: project) }
  let_it_be(:wiki_page_meta_2) { create(:wiki_page_meta, title: 'Setup Instructions', project: project) }
  let_it_be(:wiki_page_meta_3) { create(:wiki_page_meta, title: 'Deployment Pipeline', project: project) }

  before_all do
    project.add_developer(user)
  end

  describe '#execute' do
    context 'when no search term is given' do
      it 'returns all WikiPage::Meta records' do
        finder = described_class.new(user)

        result = finder.execute

        expect(result).to include(wiki_page_meta_1, wiki_page_meta_2, wiki_page_meta_3)
      end
    end

    context 'when a search term is given' do
      it 'filters by title using case-insensitive partial matching' do
        finder = described_class.new(user, search: 'deploy')

        result = finder.execute

        expect(result).to include(wiki_page_meta_1, wiki_page_meta_3)
        expect(result).not_to include(wiki_page_meta_2)
      end

      it 'is case-insensitive' do
        finder = described_class.new(user, search: 'SETUP')

        result = finder.execute

        expect(result).to include(wiki_page_meta_2)
        expect(result).not_to include(wiki_page_meta_1, wiki_page_meta_3)
      end

      it 'matches partial titles' do
        finder = described_class.new(user, search: 'Guide')

        result = finder.execute

        expect(result).to include(wiki_page_meta_1)
        expect(result).not_to include(wiki_page_meta_2, wiki_page_meta_3)
      end
    end

    context 'when search term is blank' do
      it 'returns all WikiPage::Meta records' do
        finder = described_class.new(user, search: '')

        result = finder.execute

        expect(result).to include(wiki_page_meta_1, wiki_page_meta_2, wiki_page_meta_3)
      end
    end

    context 'when a wiki page has been deleted' do
      before do
        wiki_page_meta_3.update!(deleted_at: Time.current)
      end

      it 'excludes deleted wiki page meta records' do
        finder = described_class.new(user)

        result = finder.execute

        expect(result).to include(wiki_page_meta_1, wiki_page_meta_2)
        expect(result).not_to include(wiki_page_meta_3)
      end

      it 'excludes deleted records even when matching search term' do
        finder = described_class.new(user, search: 'Deployment')

        result = finder.execute

        expect(result).to be_empty
      end
    end

    context 'when extra keyword arguments are passed' do
      it 'ignores them without error' do
        expect do
          described_class.new(user, search: 'deploy', in: 'title', skip_full_text_search_project_condition: true)
        end.not_to raise_error
      end
    end

    context 'with group wiki pages' do
      let_it_be(:public_group) { create(:group, :public) }
      let_it_be(:private_group) { create(:group, :private) }
      let_it_be(:group_wiki_meta) { create(:wiki_page_meta, title: 'Group Wiki Page', namespace: public_group) }
      let_it_be(:private_group_wiki_meta) do
        create(:wiki_page_meta, title: 'Private Group Wiki', namespace: private_group)
      end

      let(:kwargs) { {} }
      let(:finder) { described_class.new(user, **kwargs) }

      it 'returns visible group wiki page meta records and excludes non-visible ones' do
        result = finder.execute

        expect(result).to include(group_wiki_meta)
        expect(result).not_to include(private_group_wiki_meta)
      end

      context 'when user has access to the private group' do
        before_all do
          private_group.add_developer(user)
        end

        it 'includes private group wiki page meta records' do
          result = finder.execute

          expect(result).to include(
            wiki_page_meta_1, wiki_page_meta_2, wiki_page_meta_3,
            group_wiki_meta, private_group_wiki_meta
          )
        end
      end

      context 'when searching group wiki page meta records' do
        let!(:other_group_wiki_meta) { create(:wiki_page_meta, title: 'API Reference', namespace: public_group) }
        let(:kwargs) { { search: 'Group Wiki' } }

        it 'includes only matching group wiki page meta records' do
          result = finder.execute

          expect(result).to include(group_wiki_meta)
          expect(result).not_to include(other_group_wiki_meta, wiki_page_meta_1, wiki_page_meta_2, wiki_page_meta_3)
        end
      end

      context 'when a group wiki page has been deleted' do
        let_it_be(:deleted_group_meta) do
          create(:wiki_page_meta, title: 'Deleted Group Page', namespace: public_group, deleted_at: Time.current)
        end

        it 'excludes deleted group wiki page meta records' do
          result = finder.execute

          expect(result).to include(group_wiki_meta)
          expect(result).not_to include(deleted_group_meta)
        end
      end
    end
  end

  describe '#klass' do
    it 'returns WikiPage::Meta' do
      finder = described_class.new(user)

      expect(finder.klass).to eq(WikiPage::Meta)
    end
  end
end
