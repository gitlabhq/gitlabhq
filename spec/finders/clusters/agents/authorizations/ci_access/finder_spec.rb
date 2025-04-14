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

    let(:finder) { described_class.new(requesting_project) }

    subject { finder.execute }

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
      context 'when initialized without an agent' do
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

        context 'with multiple authorizations' do
          let!(:authorization1) { create(:agent_ci_access_project_authorization, agent: production_agent, project: requesting_project) }
          let!(:authorization2) { create(:agent_ci_access_project_authorization, agent: staging_agent, project: requesting_project) }

          it { is_expected.to contain_exactly(authorization1, authorization2) }
        end
      end

      context 'when initialized with an agent' do
        let!(:authorization1) { create(:agent_ci_access_project_authorization, agent: production_agent, project: requesting_project) }
        let!(:authorization2) { create(:agent_ci_access_project_authorization, agent: staging_agent, project: requesting_project) }

        let!(:finder) { described_class.new(requesting_project, agent: production_agent) }

        it 'returns authorizations for the given agent' do
          expect(subject).to contain_exactly(authorization1)
        end
      end

      it_behaves_like 'access_as' do
        let!(:authorization) { create(:agent_ci_access_project_authorization, agent: production_agent, project: requesting_project, config: config) }
      end
    end

    describe 'implicit authorizations' do
      let!(:associated_agent_1) { create(:cluster_agent, project: requesting_project) }
      let!(:associated_agent_2) { create(:cluster_agent, project: requesting_project) }

      context 'when initialized without an agent' do
        it 'returns all authorizations for agents directly associated with the project' do
          expect(subject.count).to eq(2)
          expect(subject).to all(be_a(Clusters::Agents::Authorizations::CiAccess::ImplicitAuthorization))
          expect(subject.map(&:agent)).to contain_exactly(associated_agent_1, associated_agent_2)
        end
      end

      context 'when initialized with an agent' do
        let!(:finder) { described_class.new(requesting_project, agent: associated_agent_1) }

        it 'returns authorizations for the given agent' do
          expect(subject.count).to eq(1)

          authorization = subject.first
          expect(authorization).to be_a(Clusters::Agents::Authorizations::CiAccess::ImplicitAuthorization)
          expect(authorization.agent).to eq(associated_agent_1)
        end
      end
    end

    describe 'authorized groups' do
      context 'when initialized without an agent' do
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

      context 'when initialized with an agent' do
        let(:finder) { described_class.new(requesting_project, agent: production_agent) }

        context 'multiple agents are authorized for the same group' do
          let!(:staging_auth) { create(:agent_ci_access_group_authorization, agent: staging_agent, group: bottom_level_group) }
          let!(:production_auth) { create(:agent_ci_access_group_authorization, agent: production_agent, group: bottom_level_group) }

          it 'returns authorizations for the given agent' do
            expect(subject).to contain_exactly(production_auth)
          end
        end
      end
    end

    describe 'authorized organizations' do
      before do
        stub_application_setting(organization_cluster_agent_authorization_enabled: setting_enabled)
      end

      context 'when the organization authorization application setting is enabled' do
        let(:setting_enabled) { true }

        context 'when multiple agents are authorized' do
          let!(:staging_auth) { create(:agent_ci_access_organization_authorization, agent: staging_agent) }
          let!(:production_auth) { create(:agent_ci_access_organization_authorization, agent: production_agent) }

          it 'returns authorizations for all configured agents' do
            expect(subject).to contain_exactly(production_auth, staging_auth)
          end

          context 'when a single agent is specified' do
            let(:finder) { described_class.new(requesting_project, agent: production_agent) }

            it 'returns authorizations for the given agent' do
              expect(subject).to contain_exactly(production_auth)
            end
          end
        end

        context 'agent configuration project belongs to a different organization' do
          let(:organization) { create(:organization) }
          let(:project) { create(:project, organization: organization) }
          let(:unrelated_agent) { create(:cluster_agent, project: project) }

          before do
            create(:agent_ci_access_organization_authorization, agent: unrelated_agent, organization: organization)
          end

          it { is_expected.to be_empty }
        end

        it_behaves_like 'access_as' do
          let!(:authorization) { create(:agent_ci_access_organization_authorization, agent: production_agent, config: config) }
        end
      end

      context 'when the organization authorization application setting is disabled' do
        let(:setting_enabled) { false }

        let!(:production_auth) { create(:agent_ci_access_organization_authorization, agent: production_agent) }

        it { is_expected.to be_empty }
      end
    end
  end
end
