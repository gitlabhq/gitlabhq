# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::WebHooks::ProjectHooksResolver, feature_category: :webhooks do
  include GraphqlHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project) }
  let_it_be(:project_hooks) { create_list(:project_hook, 3, project: project) }
  let_it_be(:other_project_hook) { create(:project_hook) }
  let(:current_user) { user }

  specify do
    expect(described_class).to have_nullable_graphql_type(Types::WebHooks::ProjectHookType.connection_type)
  end

  describe '#resolve' do
    context 'when the user is authorized' do
      before_all do
        project.add_maintainer(user)
      end

      context 'when resolving a single project hook' do
        it 'returns the project hook with the given id' do
          expected_project_hook = project_hooks.first
          args = { id: global_id_of(expected_project_hook) }

          expect(resolve_single_project_hook(args)).to eq(expected_project_hook)
        end

        it 'does not return project hook belonging other projects' do
          args = { id: global_id_of(other_project_hook) }

          expect(resolve_single_project_hook(args)).to be_nil
        end
      end

      context 'when resolving multiple project hooks' do
        it 'returns all project hooks on the project' do
          expect(resolve_project_hooks).to match_array(project_hooks)
        end
      end
    end

    context 'when user is not authorized' do
      before_all do
        project.add_developer(user)
      end

      it { expect(resolve_project_hooks).to be_nil }
      it { expect(resolve_single_project_hook(id: global_id_of(project_hooks.first))).to be_nil }
    end
  end

  def resolve_project_hooks
    resolve(described_class, obj: project, ctx: { current_user: current_user })
  end

  def resolve_single_project_hook(args = {})
    resolve(described_class.single, obj: project, args: args, ctx: { current_user: current_user })
  end
end
