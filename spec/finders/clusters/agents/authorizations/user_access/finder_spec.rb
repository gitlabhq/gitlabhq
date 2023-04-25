# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Clusters::Agents::Authorizations::UserAccess::Finder, feature_category: :deployment_management do
  describe '#execute' do
    let_it_be(:organization) { create(:group) }
    let_it_be(:agent_configuration_project) { create(:project, namespace: organization) }
    let_it_be(:agent) { create(:cluster_agent, project: agent_configuration_project) }
    let_it_be(:deployment_project) { create(:project, namespace: organization) }
    let_it_be(:deployment_maintainer) { create(:user).tap { |u| deployment_project.add_maintainer(u) } }
    let_it_be(:deployment_developer) { create(:user).tap { |u| deployment_project.add_developer(u) } }
    let_it_be(:deployment_guest) { create(:user).tap { |u| deployment_project.add_guest(u) } }

    let(:user) { deployment_developer }
    let(:params) { { agent: nil } }

    subject { described_class.new(user, **params).execute }

    it 'returns nothing' do
      is_expected.to be_empty
    end

    context 'with project authorizations' do
      let!(:authorization) do
        create(:agent_user_access_project_authorization, agent: agent, project: deployment_project)
      end

      it 'returns authorization' do
        is_expected.to eq([authorization])

        expect(subject.first.access_level).to eq(Gitlab::Access::DEVELOPER)
      end

      context 'when user is maintainer' do
        let(:user) { deployment_maintainer }

        it 'returns authorization' do
          is_expected.to eq([authorization])

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
          create(:agent_user_access_project_authorization, agent: agent_2, project: deployment_project)
        end

        it 'returns authorizations' do
          is_expected.to contain_exactly(authorization, authorization_2)
        end

        context 'with specific agent' do
          let(:params) { { agent: agent_2 } }

          it 'returns authorization' do
            is_expected.to eq([authorization_2])
          end
        end
      end
    end

    context 'with group authorizations' do
      let!(:authorization) do
        create(:agent_user_access_group_authorization, agent: agent, group: organization)
      end

      before_all do
        organization.add_maintainer(deployment_maintainer)
        organization.add_developer(deployment_developer)
        organization.add_guest(deployment_guest)
      end

      it 'returns authorization' do
        is_expected.to eq([authorization])

        expect(subject.first.access_level).to eq(Gitlab::Access::DEVELOPER)
      end

      context 'when user is maintainer' do
        let(:user) { deployment_maintainer }

        it 'returns authorization' do
          is_expected.to eq([authorization])

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

        it 'returns authorizations' do
          is_expected.to contain_exactly(authorization, authorization_2)
        end

        context 'with specific agent' do
          let(:params) { { agent: agent_2 } }

          it 'returns authorization' do
            is_expected.to eq([authorization_2])
          end
        end
      end

      context 'when sub-group is authorized' do
        let_it_be(:subgroup) { create(:group, parent: organization) }

        let!(:authorization) do
          create(:agent_user_access_group_authorization, agent: agent, group: subgroup)
        end

        it 'returns authorization' do
          is_expected.to eq([authorization])

          expect(subject.first.access_level).to eq(Gitlab::Access::DEVELOPER)
        end
      end
    end
  end
end
