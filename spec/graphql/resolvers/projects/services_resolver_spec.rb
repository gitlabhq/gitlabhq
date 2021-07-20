# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::Projects::ServicesResolver do
  include GraphqlHelpers

  specify do
    expect(described_class).to have_nullable_graphql_type(Types::Projects::ServiceType.connection_type)
  end

  describe '#resolve' do
    let_it_be(:user) { create(:user) }

    context 'when project does not have services' do
      let_it_be(:project) { create(:project, :private) }

      context 'when user cannot access services' do
        context 'when anonymous user' do
          it_behaves_like 'cannot access project services'
        end

        context 'when user developer' do
          before do
            project.add_developer(user)
          end

          it_behaves_like 'cannot access project services'
        end
      end

      context 'when user can read project services' do
        before do
          project.add_maintainer(user)
        end

        it_behaves_like 'no project services'
      end
    end

    context 'when project has services' do
      let_it_be(:project) { create(:project, :private) }
      let_it_be(:jira_integration) { create(:jira_integration, project: project) }

      context 'when user cannot access services' do
        context 'when anonymous user' do
          it_behaves_like 'cannot access project services'
        end

        context 'when user developer' do
          before do
            project.add_developer(user)
          end

          it_behaves_like 'cannot access project services'
        end
      end

      context 'when user can read project services' do
        before do
          project.add_maintainer(user)
        end

        it 'returns project services' do
          services = resolve_services

          expect(services.size).to eq 1
        end
      end
    end
  end

  def resolve_services(args = {}, context = { current_user: user })
    resolve(described_class, obj: project, args: args, ctx: context)
  end
end
