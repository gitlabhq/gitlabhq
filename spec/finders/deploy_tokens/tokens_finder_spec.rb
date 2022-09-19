# frozen_string_literal: true

require 'spec_helper'

RSpec.describe DeployTokens::TokensFinder do
  include AdminModeHelper

  let_it_be(:admin)      { create(:admin) }
  let_it_be(:user)       { create(:user) }
  let_it_be(:other_user) { create(:user) }
  let_it_be(:project)    { create(:project, creator_id: user.id) }
  let_it_be(:group)      { create(:group) }

  let!(:project_deploy_token) { create(:deploy_token, projects: [project]) }
  let!(:revoked_project_deploy_token) { create(:deploy_token, projects: [project], revoked: true) }
  let!(:expired_project_deploy_token) { create(:deploy_token, projects: [project], expires_at: '1988-01-11T04:33:04-0600') }
  let!(:group_deploy_token) { create(:deploy_token, :group, groups: [group]) }
  let!(:revoked_group_deploy_token) { create(:deploy_token, :group, groups: [group], revoked: true) }
  let!(:expired_group_deploy_token) { create(:deploy_token, :group, groups: [group], expires_at: '1988-01-11T04:33:04-0600') }

  describe "#execute" do
    let(:params) { {} }

    context 'when scope is :all' do
      subject { described_class.new(admin, :all, params).execute }

      before do
        enable_admin_mode!(admin)
      end

      it 'returns all deploy tokens' do
        expect(subject.size).to eq(6)
        is_expected.to match_array(
          [
            project_deploy_token,
            revoked_project_deploy_token,
            expired_project_deploy_token,
            group_deploy_token,
            revoked_group_deploy_token,
            expired_group_deploy_token
          ])
      end

      context 'and active filter is applied' do
        let(:params) { { active: true } }

        it 'returns only active tokens' do
          is_expected.to match_array(
            [
              project_deploy_token,
              group_deploy_token
            ])
        end
      end

      context 'but user is not an admin' do
        subject { described_class.new(user, :all, params).execute }

        it 'raises Gitlab::Access::AccessDeniedError' do
          expect { subject }.to raise_error(Gitlab::Access::AccessDeniedError)
        end
      end
    end

    context 'when scope is a Project' do
      subject { described_class.new(user, project, params).execute }

      before do
        project.add_maintainer(user)
      end

      it 'returns all deploy tokens for the project' do
        is_expected.to match_array(
          [
            project_deploy_token,
            revoked_project_deploy_token,
            expired_project_deploy_token
          ])
      end

      context 'and active filter is applied' do
        let(:params) { { active: true } }

        it 'returns only active tokens for the project' do
          is_expected.to match_array([project_deploy_token])
        end
      end

      context 'but user is not a member' do
        subject { described_class.new(other_user, :all, params).execute }

        it 'raises Gitlab::Access::AccessDeniedError' do
          expect { subject }.to raise_error(Gitlab::Access::AccessDeniedError)
        end
      end
    end

    context 'when scope is a Group' do
      subject { described_class.new(user, group, params).execute }

      before do
        group.add_maintainer(user)
      end

      it 'returns all deploy tokens for the group' do
        is_expected.to match_array(
          [
            group_deploy_token,
            revoked_group_deploy_token,
            expired_group_deploy_token
          ])
      end

      context 'and active filter is applied' do
        let(:params) { { active: true } }

        it 'returns only active tokens for the group' do
          is_expected.to match_array([group_deploy_token])
        end
      end

      context 'but user is not a member' do
        subject { described_class.new(other_user, :all, params).execute }

        it 'raises Gitlab::Access::AccessDeniedError' do
          expect { subject }.to raise_error(Gitlab::Access::AccessDeniedError)
        end
      end
    end

    context 'when scope is nil' do
      subject { described_class.new(user, nil, params).execute }

      it 'raises ArgumentError' do
        expect { subject }.to raise_error(ArgumentError)
      end
    end
  end
end
