# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::Ci::JobTokenScope::RemoveGroup, feature_category: :continuous_integration do
  include GraphqlHelpers

  let(:mutation) do
    described_class.new(object: nil, context: query_context, field: nil)
  end

  describe '#resolve' do
    let_it_be(:project) { create(:project, ci_inbound_job_token_scope_enabled: true).tap(&:save!) }
    let_it_be(:target_group) { create(:group, :private) }

    let_it_be(:link) do
      create(:ci_job_token_group_scope_link,
        source_project: project,
        target_group: target_group)
    end

    let(:target_group_path) { target_group.full_path }
    let(:links_relation) { Ci::JobToken::GroupScopeLink.with_source(project).with_target(target_group) }

    subject(:resolver) do
      mutation.resolve(project_path: project.full_path, target_group_path: target_group_path)
    end

    context 'when user is not logged in' do
      let_it_be(:current_user) { nil }

      it 'raises error' do
        expect { resolver }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
      end
    end

    context 'when user is logged in' do
      let_it_be(:current_user) { create(:user) }

      context 'when user does not have permissions to admin project' do
        it 'raises error' do
          expect { resolver }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
        end
      end

      context 'when user has permissions to admin project and read target project' do
        before_all do
          project.add_maintainer(current_user)
          target_group.add_guest(current_user)
        end

        let(:service) { instance_double('Ci::JobTokenScope::RemoveGroupService') }

        it 'calls the RemoveGroupService to remove a group' do
          expect(::Ci::JobTokenScope::RemoveGroupService)
            .to receive(:new).with(project, current_user).and_return(service)
          expect(service).to receive(:execute).with(target_group)
            .and_return(instance_double('ServiceResponse', success?: true, payload: link))

          resolver
        end
      end

      context 'when the service returns an error' do
        let(:service) { instance_double('Ci::JobTokenScope::RemoveGroupService') }

        before_all do
          project.add_maintainer(current_user)
          target_group.add_guest(current_user)
        end

        it 'returns an error response' do
          expect(::Ci::JobTokenScope::RemoveGroupService).to receive(:new).with(project,
            current_user).and_return(service)
          expect(service).to receive(:execute).with(target_group)
            .and_return(ServiceResponse.error(message: 'The error message'))

          expect(resolver.fetch(:ci_job_token_scope)).to be_nil
          expect(resolver.fetch(:errors)).to include("The error message")
        end
      end
    end
  end
end
