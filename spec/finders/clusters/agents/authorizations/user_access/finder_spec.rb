# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Clusters::Agents::Authorizations::UserAccess::Finder, feature_category: :deployment_management do
  describe '#execute' do
    let_it_be(:parent_group) { create(:group) }
    let_it_be(:organization) { create(:group, parent: parent_group) }
    let_it_be(:agent_configuration_project) { create(:project, namespace: organization) }
    let_it_be(:agent) { create(:cluster_agent, project: agent_configuration_project) }
    let_it_be(:deployment_project) { create(:project, namespace: organization) }
    let_it_be(:deployment_maintainer) { create(:user, maintainer_of: deployment_project) }
    let_it_be(:deployment_developer) { create(:user, developer_of: deployment_project) }
    let_it_be(:deployment_guest) { create(:user, guest_of: deployment_project) }

    let(:user) { deployment_developer }
    let(:params) { { agent: nil } }

    subject { described_class.new(user, **params).execute }

    it 'returns nothing' do
      is_expected.to be_empty
    end

    context 'with project authorizations' do
      let!(:authorization_1) do
        create(:agent_user_access_project_authorization, agent: agent, project: deployment_project)
      end

      it 'returns authorization' do
        is_expected.to contain_exactly(authorization_1)

        expect(subject.first.access_level).to eq(Gitlab::Access::DEVELOPER)
      end

      context 'when user is maintainer' do
        let(:user) { deployment_maintainer }

        it 'returns authorization' do
          is_expected.to contain_exactly(authorization_1)

          expect(subject.first.access_level).to eq(Gitlab::Access::MAINTAINER)
        end
      end

      context 'when user is guest' do
        let(:user) { deployment_guest }

        it 'does not return authorization' do
          is_expected.to be_empty
        end
      end

      context 'with multiple authorizations' do
        let_it_be(:agent_2) { create(:cluster_agent, project: agent_configuration_project) }
        let_it_be(:agent_3) { create(:cluster_agent, project: agent_configuration_project) }
        let_it_be(:deployment_project_2) { create(:project, namespace: organization) }

        let_it_be(:authorization_2) do
          create(:agent_user_access_project_authorization, agent: agent_2, project: deployment_project)
        end

        let_it_be(:authorization_3) do
          create(:agent_user_access_project_authorization, agent: agent_3, project: deployment_project_2)
        end

        before_all do
          deployment_project_2.add_developer(deployment_developer)
        end

        it 'returns authorizations' do
          is_expected.to contain_exactly(authorization_1, authorization_2, authorization_3)
        end

        context 'with specific agent' do
          let(:params) { { agent: agent_2 } }

          it 'returns authorization' do
            is_expected.to contain_exactly(authorization_2)
          end
        end

        context 'with specific project' do
          let(:params) { { project: deployment_project_2 } }

          it 'returns authorization' do
            is_expected.to contain_exactly(authorization_3)
          end
        end

        context 'with limit' do
          let(:params) { { limit: 1 } }

          it 'returns authorization' do
            expect(subject.count).to eq(1)
          end
        end
      end
    end

    context 'with group authorizations' do
      let!(:authorization_1) do
        create(:agent_user_access_group_authorization, agent: agent, group: organization)
      end

      before_all do
        organization.add_maintainer(deployment_maintainer)
        organization.add_developer(deployment_developer)
        organization.add_guest(deployment_guest)
      end

      it 'returns authorization' do
        is_expected.to contain_exactly(authorization_1)

        expect(subject.first.access_level).to eq(Gitlab::Access::DEVELOPER)
      end

      context 'when user is maintainer' do
        let(:user) { deployment_maintainer }

        it 'returns authorization' do
          is_expected.to contain_exactly(authorization_1)

          expect(subject.first.access_level).to eq(Gitlab::Access::MAINTAINER)
        end
      end

      context 'when user is guest' do
        let(:user) { deployment_guest }

        it 'does not return authorization' do
          is_expected.to be_empty
        end
      end

      context 'with multiple authorizations' do
        let_it_be(:agent_2) { create(:cluster_agent, project: agent_configuration_project) }

        let_it_be(:authorization_2) do
          create(:agent_user_access_group_authorization, agent: agent_2, group: organization)
        end

        let_it_be(:authorization_3) { create(:agent_user_access_group_authorization) }

        it 'returns authorizations' do
          is_expected.to contain_exactly(authorization_1, authorization_2)
        end

        context 'with specific agent' do
          let(:params) { { agent: agent_2 } }

          it 'returns authorization' do
            is_expected.to eq([authorization_2])
          end
        end

        context 'with specific project' do
          let(:params) { { project: deployment_project } }

          it 'returns authorization' do
            is_expected.to contain_exactly(authorization_1, authorization_2)
          end
        end

        context 'with limit' do
          let(:params) { { limit: 1 } }

          it 'returns authorization' do
            expect(subject.count).to eq(1)
          end
        end
      end

      context 'when sub-group is authorized' do
        let_it_be(:subgroup_1) { create(:group, parent: organization) }
        let_it_be(:subgroup_2) { create(:group, parent: organization) }
        let_it_be(:deployment_project_1) { create(:project, group: subgroup_1) }
        let_it_be(:deployment_project_2) { create(:project, group: subgroup_2) }

        let!(:authorization_1) { create(:agent_user_access_group_authorization, agent: agent, group: subgroup_1) }
        let!(:authorization_2) { create(:agent_user_access_group_authorization, agent: agent, group: subgroup_2) }

        it 'returns authorization' do
          is_expected.to contain_exactly(authorization_1, authorization_2)

          expect(subject.first.access_level).to eq(Gitlab::Access::DEVELOPER)
        end

        context 'with specific deployment project' do
          let(:params) { { project: deployment_project_1 } }

          it 'returns only the authorization connected to the parent group' do
            is_expected.to contain_exactly(authorization_1)
          end
        end
      end
    end

    context 'with group authorizations inherited from a parent group' do
      let!(:authorization_1) do
        create(:agent_user_access_group_authorization, agent: agent, group: parent_group)
      end

      let(:params) { { project: deployment_project } }

      before_all do
        parent_group.add_developer(deployment_developer)
      end

      it 'returns authorization' do
        is_expected.to contain_exactly(authorization_1)

        expect(subject.first.access_level).to eq(Gitlab::Access::DEVELOPER)
      end
    end
  end
end
