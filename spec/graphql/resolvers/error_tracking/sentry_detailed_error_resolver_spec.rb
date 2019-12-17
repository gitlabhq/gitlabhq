# frozen_string_literal: true

require 'spec_helper'

describe Resolvers::ErrorTracking::SentryDetailedErrorResolver do
  include GraphqlHelpers

  let_it_be(:project) { create(:project) }
  let_it_be(:current_user) { create(:user) }

  let(:issue_details_service) { spy('ErrorTracking::IssueDetailsService') }

  before do
    project.add_developer(current_user)

    allow(ErrorTracking::IssueDetailsService)
      .to receive(:new)
      .and_return issue_details_service
  end

  describe '#resolve' do
    let(:args) { { id: issue_global_id(1234) } }

    it 'fetches the data via the sentry API' do
      resolve_error(args)

      expect(issue_details_service).to have_received(:execute)
    end

    context 'error matched' do
      let(:detailed_error) { build(:detailed_error_tracking_error) }

      before do
        allow(issue_details_service).to receive(:execute)
          .and_return({ issue: detailed_error })
      end

      it 'resolves to a detailed error' do
        expect(resolve_error(args)).to eq detailed_error
      end

      it 'assigns the gitlab project' do
        expect(resolve_error(args).gitlab_project).to eq project
      end
    end

    it 'resolves to nil if no match' do
      allow(issue_details_service).to receive(:execute)
        .and_return({ issue: nil })

      result = resolve_error(args)
      expect(result).to eq nil
    end
  end

  def resolve_error(args = {}, context = { current_user: current_user })
    resolve(described_class, obj: project, args: args, ctx: context)
  end

  def issue_global_id(issue_id)
    Gitlab::ErrorTracking::DetailedError.new(id: issue_id).to_global_id.to_s
  end
end
