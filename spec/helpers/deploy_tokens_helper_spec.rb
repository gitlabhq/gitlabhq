# frozen_string_literal: true

require 'spec_helper'

RSpec.describe DeployTokensHelper, feature_category: :continuous_delivery do
  using RSpec::Parameterized::TableSyntax

  describe '#deploy_token_revoke_button_data' do
    let_it_be(:token) { build(:deploy_token) }
    let_it_be(:project) { build(:project) }
    let_it_be(:revoke_deploy_token_path) { '/foobar/baz/-/deploy_tokens/1/revoke' }

    it 'returns expected hash' do
      expect(helper).to receive(:revoke_deploy_token_path).with(project, token).and_return(revoke_deploy_token_path)

      expect(helper.deploy_token_revoke_button_data(token: token, group_or_project: project)).to match({
        token: token.to_json(only: [:id, :name]),
        revoke_path: revoke_deploy_token_path
      })
    end
  end

  describe '#container_registry_enabled?' do
    let_it_be(:project) { build(:project) }
    let_it_be(:user) { build(:user) }

    where(:registry_enabled, :can_read_container_image, :can_manage_deploy_tokens, :result) do
      true  | true  | true  | true
      true  | true  | false | true
      true  | false | true  | true
      true  | false | false | false
      false | true  | true  | false
    end

    with_them do
      before do
        allow(helper).to receive(:current_user).and_return(user)
        allow(Gitlab.config.registry).to receive(:enabled).and_return(registry_enabled)
        allow(Ability).to receive(:allowed?).and_call_original
        allow(Ability).to receive(:allowed?).with(user, :read_container_image, project)
          .and_return(can_read_container_image)
        allow(Ability).to receive(:allowed?).with(user, :manage_deploy_tokens, project)
          .and_return(can_manage_deploy_tokens)
      end

      it 'returns expected value' do
        expect(helper.container_registry_enabled?(project)).to eq(result)
      end
    end
  end

  describe '#packages_registry_enabled?' do
    let_it_be(:project) { build(:project) }
    let_it_be(:user) { build(:user) }

    where(:packages_enabled, :can_read_package, :can_manage_deploy_tokens, :result) do
      true  | true  | true  | true
      true  | true  | false | true
      true  | false | true  | true
      true  | false | false | false
      false | true  | true  | false
    end

    with_them do
      before do
        allow(helper).to receive(:current_user).and_return(user)
        allow(Gitlab.config.packages).to receive(:enabled).and_return(packages_enabled)
        allow(Ability).to receive(:allowed?).and_call_original
        allow(Ability).to receive(:allowed?).with(user, :read_package, instance_of(::Packages::Policies::Project))
          .and_return(can_read_package)
        allow(Ability).to receive(:allowed?).with(user, :manage_deploy_tokens, project)
          .and_return(can_manage_deploy_tokens)
      end

      it 'returns expected value' do
        expect(helper.packages_registry_enabled?(project)).to eq(result)
      end
    end
  end
end
