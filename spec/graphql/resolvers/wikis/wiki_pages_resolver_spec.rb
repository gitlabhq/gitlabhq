# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::Wikis::WikiPagesResolver, feature_category: :wiki do
  include GraphqlHelpers

  describe '#resolve' do
    let_it_be(:user) { create(:user) }
    let_it_be(:project, freeze: false) { create(:project, :private, developers: user) }

    context 'for project wikis' do
      let_it_be(:wiki_page_meta, freeze: false) { create(:wiki_page_meta, :for_wiki_page, container: project) }

      subject(:resolved_pages) do
        resolve_wiki_pages(project).items
      end

      it 'returns wiki page meta records' do
        expect(resolved_pages).to include(wiki_page_meta)
      end

      context 'when wiki has no pages' do
        let_it_be(:empty_project, freeze: false) { create(:project, :private, developers: user) }

        it 'returns an empty collection' do
          expect(resolve_wiki_pages(empty_project).items).to be_empty
        end
      end

      context 'with pagination' do
        let_it_be(:wiki, freeze: false) { project.wiki }

        # Together with the `wiki_page_meta` page above this gives 3 pages in total, so
        # paginating with `first: 2` yields a full first page and a partial second page.
        let_it_be(:pages, freeze: false) do
          %w[apple banana].map { |title| create(:wiki_page, wiki: wiki, title: title) }
        end

        it 'fetches one extra probe row beyond the requested page size to detect the next page' do
          allow(Wiki).to receive(:for_container).and_return(wiki)
          expect(wiki).to receive(:list_pages).with(limit: 3, offset: 0).and_call_original

          resolve_wiki_pages(project, args: { first: 2 })
        end

        it 'returns the first page with a cursor to the next page' do
          result = resolve_wiki_pages(project, args: { first: 2 })

          expect(result.items.size).to eq(2)
          expect(result.has_next_page).to be(true)
          expect(result.end_cursor).to be_present
        end

        it 'returns the next page without overlap when following the cursor' do
          first_page = resolve_wiki_pages(project, args: { first: 2 })
          second_page = resolve_wiki_pages(project, args: { first: 2, after: first_page.end_cursor })

          expect(second_page.items.size).to eq(1)
          expect(second_page.has_next_page).to be(false)
          expect(second_page.end_cursor).to be_nil

          all_titles = (first_page.items + second_page.items).map(&:title)
          expect(all_titles).to contain_exactly('apple', 'banana', wiki_page_meta.title)
        end

        it 'reports hasNextPage=false when first equals the total page count' do
          result = resolve_wiki_pages(project, args: { first: 3 })

          expect(result.items.size).to eq(3)
          expect(result.has_next_page).to be(false)
          expect(result.end_cursor).to be_nil # no phantom cursor at the boundary
        end

        it 'returns an empty result with no next page, without an unlimited fetch, when first is 0' do
          allow(Wiki).to receive(:for_container).and_return(wiki)
          expect(wiki).not_to receive(:list_pages)

          result = resolve_wiki_pages(project, args: { first: 0 })

          expect(result.items).to be_empty
          expect(result.has_next_page).to be(false)
        end

        it 'floors a negative cursor offset to zero' do
          negative_cursor = Base64.strict_encode64('-5')

          allow(Wiki).to receive(:for_container).and_return(wiki)
          expect(wiki).to receive(:list_pages).with(limit: 3, offset: 0).and_call_original

          resolve_wiki_pages(project, args: { first: 2, after: negative_cursor })
        end

        it 'returns an error for an invalid cursor' do
          expect_graphql_error_to_be_created(
            Gitlab::Graphql::Errors::ArgumentError, 'Invalid pagination cursor'
          ) do
            resolve_wiki_pages(project, args: { first: 2, after: 'not-a-valid-cursor' })
          end
        end
      end

      context 'when the user is not authorized to read the wiki' do
        let_it_be(:unauthorized_user) { create(:user) }

        it 'returns nil without running the resolver' do
          expect(resolve_wiki_pages(project, current_user: unauthorized_user)).to be_nil
        end
      end
    end
  end

  private

  def resolve_wiki_pages(container, args: {}, current_user: user)
    resolve(
      described_class,
      obj: container,
      args: args,
      ctx: { current_user: current_user },
      field_opts: {
        calls_gitaly: true,
        connection_extension: Gitlab::Graphql::Extensions::ForwardOnlyExternallyPaginatedArrayExtension
      }
    )
  end
end
