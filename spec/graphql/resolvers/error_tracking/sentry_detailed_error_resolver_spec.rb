# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::ErrorTracking::SentryDetailedErrorResolver do
  include GraphqlHelpers

  let_it_be(:project) { create(:project) }
  let_it_be(:current_user) { create(:user, developer_of: project) }

  let(:issue_details_service) { instance_double('ErrorTracking::IssueDetailsService') }
  let(:service_response) { {} }

  before do
    allow(ErrorTracking::IssueDetailsService)
      .to receive(:new)
      .and_return(issue_details_service)

    allow(issue_details_service).to receive(:execute).and_return(service_response)
  end

  specify do
    expect(described_class).to have_nullable_graphql_type(Types::ErrorTracking::SentryDetailedErrorType)
  end

  describe '#resolve' do
    let(:args) { { id: issue_global_id(1234) } }

    it 'fetches the data via the sentry API' do
      resolve_error(args)

      expect(issue_details_service).to have_received(:execute)
    end

    context 'when error matches' do
      let(:detailed_error) { build_stubbed(:error_tracking_sentry_detailed_error) }
      let(:service_response) { { issue: detailed_error } }

      it 'resolves to a detailed error' do
        expect(resolve_error(args)).to eq detailed_error
      end

      it 'assigns the gitlab project' do
        expect(resolve_error(args).gitlab_project).to eq project
      end
    end

    context 'when id does not match issue' do
      let(:service_response) { { issue: nil } }

      it 'resolves to nil' do
        result = resolve_error(args)
        expect(result).to be_nil
      end
    end
  end

  private

  def resolve_error(args = {}, context = { current_user: current_user })
    resolve(described_class, obj: project, args: args, ctx: context)
  end

  def issue_global_id(issue_id)
    Gitlab::ErrorTracking::DetailedError.new(id: issue_id).to_global_id
  end
end
