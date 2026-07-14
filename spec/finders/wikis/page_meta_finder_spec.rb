# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Wikis::PageMetaFinder, feature_category: :wiki do
  let_it_be(:user, freeze: true) { create(:user) }
  let_it_be(:project, freeze: true) { create(:project) }
  let_it_be(:wiki_page_meta_1, freeze: true) { create(:wiki_page_meta, title: 'Deploy Guide', project: project) }
  let_it_be(:wiki_page_meta_2, freeze: true) { create(:wiki_page_meta, title: 'Setup Instructions', project: project) }
  let_it_be_with_reload(:wiki_page_meta_3) do
    create(:wiki_page_meta, title: 'Deployment Pipeline', project: project)
  end

  before_all do
    project.add_developer(user)
  end

  describe '#execute' do
    let(:kwargs) { {} }

    subject(:result) { described_class.new(user, **kwargs).execute }

    context 'when no search term is given' do
      it 'returns all WikiPage::Meta records' do
        expect(result).to include(wiki_page_meta_1, wiki_page_meta_2, wiki_page_meta_3)
      end
    end

    context 'when a search term is given' do
      context 'with a matching term' do
        let(:kwargs) { { search: 'deploy' } }

        it 'filters by title using partial matching', :aggregate_failures do
          expect(result).to include(wiki_page_meta_1, wiki_page_meta_3)
          expect(result).not_to include(wiki_page_meta_2)
        end
      end

      context 'with an uppercase term' do
        let(:kwargs) { { search: 'SETUP' } }

        it 'is case-insensitive', :aggregate_failures do
          expect(result).to include(wiki_page_meta_2)
          expect(result).not_to include(wiki_page_meta_1, wiki_page_meta_3)
        end
      end

      context 'with a partial title' do
        let(:kwargs) { { search: 'Guide' } }

        it 'matches partial titles', :aggregate_failures do
          expect(result).to include(wiki_page_meta_1)
          expect(result).not_to include(wiki_page_meta_2, wiki_page_meta_3)
        end
      end
    end

    context 'when search term is blank' do
      let(:kwargs) { { search: '' } }

      it 'returns all WikiPage::Meta records' do
        expect(result).to include(wiki_page_meta_1, wiki_page_meta_2, wiki_page_meta_3)
      end
    end

    context 'when a wiki page has been deleted' do
      before do
        wiki_page_meta_3.update!(deleted_at: Time.current)
      end

      it 'excludes deleted wiki page meta records', :aggregate_failures do
        expect(result).to include(wiki_page_meta_1, wiki_page_meta_2)
        expect(result).not_to include(wiki_page_meta_3)
      end

      context 'when matching search term' do
        let(:kwargs) { { search: 'Deployment' } }

        it 'excludes deleted records even when matching search term' do
          expect(result).to be_empty
        end
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
      let_it_be(:public_group, freeze: true) { create(:group, :public) }
      let_it_be(:private_group, freeze: true) { create(:group, :private) }
      let_it_be(:group_wiki_meta, freeze: true) do
        create(:wiki_page_meta, title: 'Group Wiki Page', namespace: public_group)
      end

      let_it_be(:private_group_wiki_meta, freeze: true) do
        create(:wiki_page_meta, title: 'Private Group Wiki', namespace: private_group)
      end

      it 'returns visible group wiki page meta records and excludes non-visible ones', :aggregate_failures do
        expect(result).to include(group_wiki_meta)
        expect(result).not_to include(private_group_wiki_meta)
      end

      context 'when user has access to the private group' do
        before_all do
          private_group.add_developer(user)
        end

        it 'includes private group wiki page meta records' do
          expect(result).to include(
            wiki_page_meta_1, wiki_page_meta_2, wiki_page_meta_3,
            group_wiki_meta, private_group_wiki_meta
          )
        end
      end

      context 'when searching group wiki page meta records' do
        let_it_be(:other_group_wiki_meta, freeze: true) do
          create(:wiki_page_meta, title: 'API Reference', namespace: public_group)
        end

        let(:kwargs) { { search: 'Group Wiki' } }

        it 'includes only matching group wiki page meta records', :aggregate_failures do
          expect(result).to include(group_wiki_meta)
          expect(result).not_to include(other_group_wiki_meta, wiki_page_meta_1, wiki_page_meta_2, wiki_page_meta_3)
        end
      end

      context 'when a group wiki page has been deleted' do
        let_it_be(:deleted_group_meta, freeze: true) do
          create(:wiki_page_meta, title: 'Deleted Group Page', namespace: public_group, deleted_at: Time.current)
        end

        it 'excludes deleted group wiki page meta records', :aggregate_failures do
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
