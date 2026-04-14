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

    context 'when extra keyword arguments are passed' do
      it 'ignores them without error' do
        expect do
          described_class.new(user, search: 'deploy', in: 'title', skip_full_text_search_project_condition: true)
        end.not_to raise_error
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
