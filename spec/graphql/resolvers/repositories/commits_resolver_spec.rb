# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::Repositories::CommitsResolver, feature_category: :source_code_management do
  include GraphqlHelpers

  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:repository) { project.repository }

  it { expect(described_class).to have_nullable_graphql_type(Types::Repositories::CommitType.connection_type) }

  describe '#resolve' do
    let(:ref) { 'master' }
    let(:query) { nil }
    let(:author) { nil }
    let(:committed_before) { nil }
    let(:committed_after) { nil }
    let(:first) { nil }
    let(:after) { nil }
    let(:commits) { resolved.items }
    let(:max_page_size) { 100 }
    let(:schema) { GitlabSchema }

    let(:arguments) do
      {
        ref: ref,
        query: query,
        author: author,
        committed_before: committed_before,
        committed_after: committed_after,
        first: first,
        after: after
      }
    end

    subject(:resolved) do
      field = ::Types::BaseField.from_options(
        'field_value',
        name: 'commits',
        owner: resolver_parent,
        resolver_class: described_class,
        connection_extension: Gitlab::Graphql::Extensions::ForwardOnlyExternallyPaginatedArrayExtension,
        calls_gitaly: true,
        null: true,
        max_page_size: max_page_size
      )

      resolve_field(field, repository, args: arguments, object_type: resolver_parent, schema: schema)
    end

    context 'when a valid ref is supplied' do
      it 'resolves commits' do
        expect(commits).to eq(repository.list_commits(ref: ref).commits)
      end

      it 'returns an externally paginated array' do
        is_expected.to be_a(Gitlab::Graphql::Pagination::ExternallyPaginatedArrayConnection)
      end

      it 'includes start_cursor and end_cursor for pagination' do
        expect(resolved.start_cursor).to eq(Base64.encode64(resolved.items.first.sha))
        expect(resolved.end_cursor).to eq(Base64.encode64(resolved.items.last.sha))
      end

      describe 'query' do
        let(:query) { 'Merge branch' }

        it 'returns commits with messages matching the query' do
          expect(commits.map(&:title)).to all start_with(query)
        end
      end

      describe 'author' do
        let(:author) { 'Stan' }

        it 'returns commits authored by the supplied author name pattern' do
          expect(commits.map(&:author_name)).to all start_with(author)
        end
      end

      describe 'pagination params' do
        before do
          allow(repository).to receive(:list_commits).and_return([])
        end

        context 'and field defines a max_page_size' do
          let(:max_page_size) { 2 }

          context 'with a valid limit' do
            let(:first) { max_page_size - 1 }

            it 'uses the passed value' do
              resolved
              expect(repository)
                .to have_received(:list_commits)
                .with(a_hash_including(pagination_params: { limit: first }))
            end
          end

          context 'with a limit exceeding the max_page_size' do
            let(:first) { max_page_size + 1 }

            it 'respects the max_page_size' do
              resolved
              expect(repository)
                .to have_received(:list_commits)
                .with(a_hash_including(pagination_params: { limit: max_page_size }))
            end
          end
        end

        context 'and schema defines default_max_page_size' do
          let(:max_page_size) { nil }
          let(:default_max_page_size) { 2 }
          let(:schema) do
            Class.new(GitlabSchema) do
              default_max_page_size 2
            end
          end

          context 'with a valid limit' do
            let(:first) { default_max_page_size - 1 }

            it 'uses the passed value' do
              resolved
              expect(repository)
                .to have_received(:list_commits)
                .with(a_hash_including(pagination_params: { limit: first }))
            end
          end

          context 'with a limit exceeding the default_max_page_size' do
            let(:first) { default_max_page_size + 1 }

            it 'respects the default_max_page_size' do
              resolved
              expect(repository)
                .to have_received(:list_commits)
                .with(a_hash_including(pagination_params: { limit: default_max_page_size }))
            end
          end
        end

        context 'with no limit' do
          it 'picks the fields max_page_size' do
            resolved
            expect(repository)
              .to have_received(:list_commits)
              .with(a_hash_including(pagination_params: { limit: max_page_size }))
          end
        end

        context 'with a page_token' do
          # Currently we are manually encoding these tokens as gitaly doesn't
          # yet. Once gitaly starts returning tokens we can remove this
          # encode/decode step
          let(:after) { Base64.encode64('page_token') }

          it 'passes the decoded page_token' do
            resolved
            expect(repository)
              .to have_received(:list_commits)
              .with(a_hash_including(pagination_params: { limit: max_page_size, page_token: Base64.decode64(after) }))
          end
        end
      end

      describe 'committed_before' do
        context 'when valid' do
          let(:committed_before) { '2015-01-01' }
          let(:before_date) { committed_before.to_date }

          it 'only returns commits before the supplied date' do
            expect(commits).to be_present
            committed_ats = commits.map(&:timestamp).map(&:to_date)
            expect(committed_ats).to all be <= before_date
          end
        end

        context 'when invalid' do
          let(:committed_before) { 'xxx' }
          let(:error_class) { GraphQL::CoercionError }
          let(:error_msg) { 'no time information in "xxx"' }

          it 'error' do
            expect_graphql_error_to_be_created(error_class, error_msg) { resolved }
          end
        end
      end

      describe 'committed_after' do
        context 'when valid' do
          let(:committed_after) { '2015-01-01' }
          let(:after_date) { committed_after.to_date }

          it 'only returns commits after the supplied date' do
            expect(commits).to be_present
            committed_ats = commits.map(&:timestamp).map(&:to_date)
            expect(committed_ats).to all be >= after_date
          end
        end

        context 'when invalid' do
          let(:committed_after) { 'xxx' }
          let(:error_class) { GraphQL::CoercionError }
          let(:error_msg) { 'no time information in "xxx"' }

          it 'error' do
            expect_graphql_error_to_be_created(error_class, error_msg) { resolved }
          end
        end
      end
    end

    context 'when ref is not found' do
      let(:ref) { 'unknown' }
      let(:error_class) { Gitlab::Graphql::Errors::BaseError }
      let(:error_msg) { 'ListCommits: Gitlab::Git::CommandError' }

      it { expect_graphql_error_to_be_created(error_class, error_msg) { resolved } }
    end

    context 'when ref is empty' do
      let(:ref) { '' }

      it { expect(resolved.items).to be_empty }
    end

    context 'when ref is null' do
      let(:ref) { nil }
      let(:error_class) { GraphQL::ExecutionError }
      let(:error_msg) { "`null` is not a valid input for `String!`, please provide a value for this argument." }

      it { expect_graphql_error_to_be_created(error_class, error_msg) { resolved } }
    end
  end
end
