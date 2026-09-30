# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::Repositories::TagsResolver, feature_category: :source_code_management do
  include GraphqlHelpers

  let_it_be(:project) { create(:project, :repository) }

  let(:repository) { project.repository }
  let(:all_tag_names) { repository.tags_sorted_by('name_asc').map(&:name) }

  it { expect(described_class).to have_nullable_graphql_type(Types::Repositories::TagType.connection_type) }

  describe '#resolve' do
    let(:search) { nil }
    let(:sort) { 'updated_desc' }
    let(:first) { nil }
    let(:after) { nil }
    let(:max_page_size) { 100 }
    let(:tags) { resolved.items }

    let(:arguments) do
      { search: search, sort: sort, first: first, after: after }
    end

    let(:field_instance) do
      ::Types::BaseField.new(
        name: 'tags',
        owner: resolver_parent,
        resolver_class: described_class,
        connection_extension: Gitlab::Graphql::Extensions::ForwardOnlyExternallyPaginatedArrayExtension,
        calls_gitaly: true,
        null: true,
        max_page_size: max_page_size
      )
    end

    subject(:resolved) do
      resolve_field(field_instance, repository, args: arguments, object_type: resolver_parent, schema: GitlabSchema)
    end

    it 'returns every tag on a single page when the limit is not reached' do
      expect(tags.map(&:name)).to match_array(all_tag_names)
      expect(resolved).to be_a(Gitlab::Graphql::Pagination::ExternallyPaginatedArrayConnection)
      expect(resolved.end_cursor).to be_nil
      expect(resolved.has_next_page).to be(false)
    end

    it 'sorts by the most recently updated tag by default' do
      expect(tags.map(&:name)).to eq(repository.tags_sorted_by('updated_desc').map(&:name))
    end

    context 'when sorting by name' do
      let(:sort) { 'name_asc' }

      it 'returns tags in name order' do
        expect(tags.map(&:name)).to eq(all_tag_names)
      end
    end

    context 'when paginating through Gitaly' do
      let(:sort) { 'name_asc' }
      let(:first) { 1 }

      it 'returns the first page with a cursor to the next one' do
        expect(tags.map(&:name)).to eq(all_tag_names.first(1))
        expect(resolved.has_next_page).to be(true)
        expect(Base64.strict_decode64(resolved.end_cursor)).to eq(all_tag_names.first)
      end

      context 'when a cursor is given' do
        let(:after) { Base64.strict_encode64(all_tag_names.first) }

        it 'returns the tags after the cursor' do
          expect(tags.map(&:name)).to eq(all_tag_names.drop(1).first(1))
        end
      end

      context 'when the cursor points at the last tag' do
        let(:after) { Base64.strict_encode64(all_tag_names.last) }

        it 'returns an empty page without a next cursor' do
          expect(tags).to be_empty
          expect(resolved.has_next_page).to be(false)
          expect(resolved.end_cursor).to be_nil
        end
      end

      context 'when the cursor is not a known tag' do
        let(:after) { Base64.strict_encode64('unknown-tag') }

        it 'returns an argument error' do
          expect_graphql_error_to_be_created(Gitlab::Graphql::Errors::ArgumentError, /Invalid page token/) { resolved }
        end
      end

      context 'when the cursor is not base64' do
        let(:after) { '%%%' }

        it 'returns an argument error' do
          expect_graphql_error_to_be_created(Gitlab::Graphql::Errors::ArgumentError, /Invalid page token/) { resolved }
        end
      end
    end

    context 'when searching' do
      let(:sort) { 'name_asc' }
      let(:search) { 'v1.1' }
      let(:matching_tag_names) { all_tag_names.grep(/v1\.1/) }

      it 'returns only the matching tags' do
        expect(matching_tag_names).not_to be_empty
        expect(tags.map(&:name)).to eq(matching_tag_names)
        expect(resolved.has_next_page).to be(false)
      end

      context 'with a page size smaller than the number of matches' do
        let(:first) { 1 }

        it 'paginates the filtered list in memory' do
          expect(tags.map(&:name)).to eq(matching_tag_names.first(1))
          expect(resolved.has_next_page).to be(true)
          expect(Base64.strict_decode64(resolved.end_cursor)).to eq(matching_tag_names.first)
        end

        context 'when a cursor is given' do
          let(:after) { Base64.strict_encode64(matching_tag_names.first) }

          it 'returns the matches after the cursor' do
            expect(tags.map(&:name)).to eq(matching_tag_names.drop(1).first(1))
          end
        end

        context 'when the cursor does not match any tag' do
          let(:after) { Base64.strict_encode64('unknown-tag') }

          it 'returns an argument error' do
            expect_graphql_error_to_be_created(Gitlab::Graphql::Errors::ArgumentError, /Invalid page token/) { resolved }
          end
        end
      end

      context 'when nothing matches' do
        let(:search) { 'no-such-tag' }

        it 'returns an empty page' do
          expect(tags).to be_empty
          expect(resolved.has_next_page).to be(false)
        end
      end
    end

    context 'when the requested page size is larger than max_page_size' do
      let(:max_page_size) { 1 }
      let(:first) { 50 }
      let(:sort) { 'name_asc' }

      it 'caps the page at max_page_size' do
        expect(tags.map(&:name)).to eq(all_tag_names.first(1))
        expect(resolved.has_next_page).to be(true)
      end
    end

    context 'when first is zero' do
      let(:first) { 0 }

      it 'returns an empty page without calling Gitaly' do
        expect(::TagsFinder).not_to receive(:new)

        expect(tags).to be_empty
        expect(resolved.has_next_page).to be(false)
      end
    end
  end
end
