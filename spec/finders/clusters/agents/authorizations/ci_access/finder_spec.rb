# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Clusters::Agents::Authorizations::CiAccess::Finder, feature_category: :deployment_management do
  describe '#execute' do
    let_it_be(:top_level_group) { create(:group) }
    let_it_be(:subgroup1) { create(:group, parent: top_level_group) }
    let_it_be(:subgroup2) { create(:group, parent: subgroup1) }
    let_it_be(:bottom_level_group) { create(:group, parent: subgroup2) }

    let_it_be(:non_ancestor_group) { create(:group, parent: top_level_group) }
    let_it_be(:non_ancestor_project) { create(:project, namespace: non_ancestor_group) }
    let_it_be(:non_ancestor_agent) { create(:cluster_agent, project: non_ancestor_project) }

    let_it_be(:agent_configuration_project) { create(:project, namespace: subgroup1) }
    let_it_be(:requesting_project, reload: true) { create(:project, namespace: bottom_level_group) }

    let_it_be(:staging_agent) { create(:cluster_agent, project: agent_configuration_project) }
    let_it_be(:production_agent) { create(:cluster_agent, project: agent_configuration_project) }

    subject { described_class.new(requesting_project).execute }

    shared_examples_for 'access_as' do
      let(:config) { { access_as: { access_as => {} } } }

      context 'agent' do
        let(:access_as) { :agent }

        it { is_expected.to match_array [authorization] }
      end

      context 'impersonate' do
        let(:access_as) { :impersonate }

        it { is_expected.to be_empty }
      end

      context 'ci_user' do
        let(:access_as) { :ci_user }

        it { is_expected.to be_empty }
      end

      context 'ci_job' do
        let(:access_as) { :ci_job }

        it { is_expected.to be_empty }
      end
    end

    describe 'project authorizations' do
      context 'agent configuration project does not share a root namespace with the given project' do
        let(:unrelated_agent) { create(:cluster_agent) }

        before do
          create(:agent_ci_access_project_authorization, agent: unrelated_agent, project: requesting_project)
        end

        it { is_expected.to be_empty }
      end

      context 'agent configuration project shares a root namespace, but does not belong to an ancestor of the given project' do
        let!(:project_authorization) { create(:agent_ci_access_project_authorization, agent: non_ancestor_agent, project: requesting_project) }

        it { is_expected.to match_array([project_authorization]) }
      end

      context 'with project authorizations present' do
        let!(:authorization) { create(:agent_ci_access_project_authorization, agent: production_agent, project: requesting_project) }

        it { is_expected.to match_array [authorization] }
      end

      context 'with overlapping authorizations' do
        let!(:agent) { create(:cluster_agent, project: requesting_project) }
        let!(:project_authorization) { create(:agent_ci_access_project_authorization, agent: agent, project: requesting_project) }
        let!(:group_authorization) { create(:agent_ci_access_group_authorization, agent: agent, group: bottom_level_group) }

        it { is_expected.to match_array [project_authorization] }
      end

      it_behaves_like 'access_as' do
        let!(:authorization) { create(:agent_ci_access_project_authorization, agent: production_agent, project: requesting_project, config: config) }
      end
    end

    describe 'implicit authorizations' do
      let!(:associated_agent) { create(:cluster_agent, project: requesting_project) }

      it 'returns authorizations for agents directly associated with the project' do
        expect(subject.count).to eq(1)

        authorization = subject.first
        expect(authorization).to be_a(Clusters::Agents::Authorizations::CiAccess::ImplicitAuthorization)
        expect(authorization.agent).to eq(associated_agent)
      end
    end

    describe 'authorized groups' do
      context 'agent configuration project is outside the requesting project hierarchy' do
        let(:unrelated_agent) { create(:cluster_agent) }

        before do
          create(:agent_ci_access_group_authorization, agent: unrelated_agent, group: top_level_group)
        end

        it { is_expected.to be_empty }
      end

      context 'multiple agents are authorized for the same group' do
        let!(:staging_auth) { create(:agent_ci_access_group_authorization, agent: staging_agent, group: bottom_level_group) }
        let!(:production_auth) { create(:agent_ci_access_group_authorization, agent: production_agent, group: bottom_level_group) }

        it 'returns authorizations for all agents' do
          expect(subject).to contain_exactly(staging_auth, production_auth)
        end
      end

      context 'a single agent is authorized to more than one matching group' do
        let!(:bottom_level_auth) { create(:agent_ci_access_group_authorization, agent: production_agent, group: bottom_level_group) }
        let!(:top_level_auth) { create(:agent_ci_access_group_authorization, agent: production_agent, group: top_level_group) }

        it 'picks the authorization for the closest group to the requesting project' do
          expect(subject).to contain_exactly(bottom_level_auth)
        end
      end

      context 'agent configuration project does not belong to an ancestor of the authorized group' do
        let!(:group_authorization) { create(:agent_ci_access_group_authorization, agent: non_ancestor_agent, group: bottom_level_group) }

        it { is_expected.to match_array([group_authorization]) }
      end

      it_behaves_like 'access_as' do
        let!(:authorization) { create(:agent_ci_access_group_authorization, agent: production_agent, group: top_level_group, config: config) }
      end
    end
  end
end
