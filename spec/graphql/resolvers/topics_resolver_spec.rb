# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::TopicsResolver do
  include GraphqlHelpers

  describe '#resolve' do
    let_it_be(:organization) { create(:organization) }
    let(:organization_id) { organization.to_global_id }

    let(:topic1) do
      create(:topic, name: 'GitLab', non_private_projects_count: 1, organization: organization)
    end

    let(:topic2) do
      create(:topic, name: 'git', non_private_projects_count: 2, organization: organization)
    end

    let(:topic3) do
      create(:topic, name: 'topic3', non_private_projects_count: 3, organization: organization)
    end

    shared_examples 'topics query' do
      it 'finds all topics' do
        expect(resolve_topics).to eq([topic3, topic2, topic1])
      end

      context 'with search' do
        it 'searches environment by name' do
          expect(resolve_topics(search: 'git')).to eq([topic2, topic1])
        end

        context 'when the search term does not match any topic' do
          it 'is empty' do
            expect(resolve_topics(search: 'nonsense')).to be_empty
          end
        end
      end

      context 'with organization id' do
        it 'finds all topics' do
          expect(resolve_topics(organization_id: organization_id)).to eq([topic3, topic2, topic1])
        end

        it 'matches searched organization topics' do
          expect(resolve_topics(organization_id: organization_id, search: 'topic')).to eq([topic3])
        end
      end
    end

    shared_examples 'resource not available' do
      it 'raises a GraphQL exception' do
        expect_graphql_error_to_be_created(Gitlab::Graphql::Errors::ResourceNotAvailable) do
          resolve_topics(organization_id: organization_id)
        end
      end
    end

    context 'when no current user is set' do
      let_it_be(:organization) { create(:organization, :public) }
      let(:user) { nil }

      it_behaves_like 'topics query'
    end

    context 'when no current user is set having no public organization' do
      let(:user) { nil }

      before do
        Organizations::Organization.update_all(visibility_level: Organizations::Organization::INTERNAL)
      end

      it_behaves_like 'resource not available'
    end

    context 'when current user is set' do
      let_it_be(:user) { create(:user, organizations: [organization]) }

      it_behaves_like 'topics query'
    end

    context 'when current user is not a member of the organization' do
      let_it_be(:user) { create(:user) }
      let_it_be(:private_organization) { create(:organization, :private) }

      let(:organization_id) { private_organization.to_global_id }

      it_behaves_like 'resource not available'
    end
  end

  def resolve_topics(args = {})
    args[:organization_id] = organization.to_global_id unless args[:organization_id]
    resolve(described_class, args: args, ctx: { current_user: user })
  end
end
