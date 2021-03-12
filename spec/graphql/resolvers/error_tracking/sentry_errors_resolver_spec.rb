# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::ErrorTracking::SentryErrorsResolver do
  include GraphqlHelpers

  let_it_be(:project) { create(:project) }
  let_it_be(:current_user) { create(:user) }
  let_it_be(:error_collection) { Gitlab::ErrorTracking::ErrorCollection.new(project: project) }

  let(:list_issues_service) { spy('ErrorTracking::ListIssuesService') }

  let(:issues) { nil }
  let(:pagination) { nil }

  specify do
    expect(described_class).to have_nullable_graphql_type(Types::ErrorTracking::SentryErrorType.connection_type)
  end

  describe '#resolve' do
    context 'with insufficient user permission' do
      let(:user) { create(:user) }

      it 'returns nil' do
        context = { current_user: user }

        expect(resolve_errors({}, context)).to eq nil
      end
    end

    context 'with sufficient permission' do
      before do
        project.add_developer(current_user)

        allow(ErrorTracking::ListIssuesService)
          .to receive(:new)
          .and_return list_issues_service
      end

      context 'when after arg given' do
        let(:after) { "1576029072000:0:0" }

        it 'gives the cursor arg' do
          expect(ErrorTracking::ListIssuesService)
            .to receive(:new)
            .with(project, current_user, { cursor: after })
            .and_return list_issues_service

          resolve_errors({ after: after })
        end
      end

      context 'when no issues fetched' do
        before do
          allow(list_issues_service)
            .to receive(:execute)
            .and_return(
              issues: nil
            )
        end
        it 'returns nil' do
          expect(resolve_errors).to eq nil
        end
      end

      context 'when issues returned' do
        let(:issues) { [:issue_1, :issue_2] }
        let(:pagination) do
          {
            'next' => { 'cursor' => 'next' },
            'previous' => { 'cursor' => 'prev' }
          }
        end

        before do
          allow(list_issues_service)
            .to receive(:execute)
            .and_return(
              issues: issues,
              pagination: pagination
            )
        end

        it 'sets the issues' do
          expect(resolve_errors).to contain_exactly(*issues)
        end

        it 'sets the pagination variables' do
          result = resolve_errors
          expect(result.end_cursor).to eq 'next'
          expect(result.start_cursor).to eq 'prev'
        end

        it 'returns an externally paginated array' do
          expect(resolve_errors).to be_a Gitlab::Graphql::Pagination::ExternallyPaginatedArrayConnection
        end
      end
    end
  end

  private

  def resolve_errors(args = {}, context = { current_user: current_user })
    resolve(described_class, obj: error_collection, args: args, ctx: context)
  end
end
