# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::ErrorTracking::SentryErrorCollectionResolver do
  include GraphqlHelpers

  let_it_be(:project) { create(:project) }
  let_it_be(:current_user) { create(:user, developer_of: project) }

  let(:list_issues_service) { instance_double('ErrorTracking::ListIssuesService') }

  before do
    allow(ErrorTracking::ListIssuesService)
      .to receive(:new)
      .and_return list_issues_service

    allow(list_issues_service).to receive(:external_url)
  end

  specify do
    expect(described_class).to have_nullable_graphql_type(Types::ErrorTracking::SentryErrorCollectionType)
  end

  describe '#resolve' do
    it 'returns an error collection object' do
      expect(resolve_error_collection).to be_a Gitlab::ErrorTracking::ErrorCollection
    end

    it 'provides the service url' do
      fake_url = 'http://test.com'

      expect(list_issues_service)
        .to receive(:external_url)
        .and_return(fake_url)

      expect(resolve_error_collection.external_url).to eq fake_url
    end

    it 'provides the project' do
      expect(resolve_error_collection.project).to eq project
    end
  end

  private

  def resolve_error_collection(context = { current_user: current_user })
    resolve(described_class, obj: project, args: {}, ctx: context)
  end
end
