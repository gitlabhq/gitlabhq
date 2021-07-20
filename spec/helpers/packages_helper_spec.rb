# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PackagesHelper do
  using RSpec::Parameterized::TableSyntax

  let_it_be_with_reload(:project) { create(:project) }
  let_it_be(:base_url) { "#{Gitlab.config.gitlab.url}/api/v4/" }

  describe '#package_registry_instance_url' do
    it 'returns conan instance url when registry_type is conant' do
      url = helper.package_registry_instance_url(:conan)

      expect(url).to eq("#{base_url}packages/conan")
    end

    it 'returns npm instance url when registry_type is npm' do
      url = helper.package_registry_instance_url(:npm)

      expect(url).to eq("#{base_url}packages/npm")
    end
  end

  describe '#package_registry_project_url' do
    it 'returns maven registry url when registry_type is not provided' do
      url = helper.package_registry_project_url(1)

      expect(url).to eq("#{base_url}projects/1/packages/maven")
    end

    it 'returns specified registry url when registry_type is provided' do
      url = helper.package_registry_project_url(1, :npm)

      expect(url).to eq("#{base_url}projects/1/packages/npm")
    end
  end

  describe '#pypi_registry_url' do
    let_it_be(:base_url_with_token) { base_url.sub('://', '://__token__:<your_personal_token>@') }

    it 'returns the pypi registry url' do
      url = helper.pypi_registry_url(1)

      expect(url).to eq("#{base_url_with_token}projects/1/packages/pypi/simple")
    end
  end

  describe '#composer_registry_url' do
    it 'return the composer registry url' do
      url = helper.composer_registry_url(1)

      expect(url).to eq("#{base_url}group/1/-/packages/composer/packages.json")
    end
  end

  describe '#composer_config_repository_name' do
    let(:host) { Gitlab.config.gitlab.host }
    let(:group_id) { 1 }

    it 'return global unique composer registry id' do
      id = helper.composer_config_repository_name(group_id)

      expect(id).to eq("#{host}/#{group_id}")
    end
  end

  describe '#show_cleanup_policy_on_alert' do
    let_it_be(:user) { create(:user) }
    let_it_be_with_reload(:container_repository) { create(:container_repository) }

    subject { helper.show_cleanup_policy_on_alert(project.reload) }

    where(:com, :config_registry, :project_registry, :historic_entries, :historic_entry, :nil_policy, :container_repositories_exist, :expected_result) do
      false | false | false | false | false | false | false | false
      false | false | false | false | false | false | true  | false
      false | false | false | false | false | true  | false | false
      false | false | false | false | false | true  | true  | false
      false | false | false | false | true  | false | false | false
      false | false | false | false | true  | false | true  | false
      false | false | false | false | true  | true  | false | false
      false | false | false | false | true  | true  | true  | false
      false | false | false | true  | false | false | false | false
      false | false | false | true  | false | false | true  | false
      false | false | false | true  | false | true  | false | false
      false | false | false | true  | false | true  | true  | false
      false | false | false | true  | true  | false | false | false
      false | false | false | true  | true  | false | true  | false
      false | false | false | true  | true  | true  | false | false
      false | false | false | true  | true  | true  | true  | false
      false | false | true  | false | false | false | false | false
      false | false | true  | false | false | false | true  | false
      false | false | true  | false | false | true  | false | false
      false | false | true  | false | false | true  | true  | false
      false | false | true  | false | true  | false | false | false
      false | false | true  | false | true  | false | true  | false
      false | false | true  | false | true  | true  | false | false
      false | false | true  | false | true  | true  | true  | false
      false | false | true  | true  | false | false | false | false
      false | false | true  | true  | false | false | true  | false
      false | false | true  | true  | false | true  | false | false
      false | false | true  | true  | false | true  | true  | false
      false | false | true  | true  | true  | false | false | false
      false | false | true  | true  | true  | false | true  | false
      false | false | true  | true  | true  | true  | false | false
      false | false | true  | true  | true  | true  | true  | false
      false | true  | false | false | false | false | false | false
      false | true  | false | false | false | false | true  | false
      false | true  | false | false | false | true  | false | false
      false | true  | false | false | false | true  | true  | false
      false | true  | false | false | true  | false | false | false
      false | true  | false | false | true  | false | true  | false
      false | true  | false | false | true  | true  | false | false
      false | true  | false | false | true  | true  | true  | false
      false | true  | false | true  | false | false | false | false
      false | true  | false | true  | false | false | true  | false
      false | true  | false | true  | false | true  | false | false
      false | true  | false | true  | false | true  | true  | false
      false | true  | false | true  | true  | false | false | false
      false | true  | false | true  | true  | false | true  | false
      false | true  | false | true  | true  | true  | false | false
      false | true  | false | true  | true  | true  | true  | false
      false | true  | true  | false | false | false | false | false
      false | true  | true  | false | false | false | true  | false
      false | true  | true  | false | false | true  | false | false
      false | true  | true  | false | false | true  | true  | false
      false | true  | true  | false | true  | false | false | false
      false | true  | true  | false | true  | false | true  | false
      false | true  | true  | false | true  | true  | false | false
      false | true  | true  | false | true  | true  | true  | false
      false | true  | true  | true  | false | false | false | false
      false | true  | true  | true  | false | false | true  | false
      false | true  | true  | true  | false | true  | false | false
      false | true  | true  | true  | false | true  | true  | false
      false | true  | true  | true  | true  | false | false | false
      false | true  | true  | true  | true  | false | true  | false
      false | true  | true  | true  | true  | true  | false | false
      false | true  | true  | true  | true  | true  | true  | false
      true  | false | false | false | false | false | false | false
      true  | false | false | false | false | false | true  | false
      true  | false | false | false | false | true  | false | false
      true  | false | false | false | false | true  | true  | false
      true  | false | false | false | true  | false | false | false
      true  | false | false | false | true  | false | true  | false
      true  | false | false | false | true  | true  | false | false
      true  | false | false | false | true  | true  | true  | false
      true  | false | false | true  | false | false | false | false
      true  | false | false | true  | false | false | true  | false
      true  | false | false | true  | false | true  | false | false
      true  | false | false | true  | false | true  | true  | false
      true  | false | false | true  | true  | false | false | false
      true  | false | false | true  | true  | false | true  | false
      true  | false | false | true  | true  | true  | false | false
      true  | false | false | true  | true  | true  | true  | false
      true  | false | true  | false | false | false | false | false
      true  | false | true  | false | false | false | true  | false
      true  | false | true  | false | false | true  | false | false
      true  | false | true  | false | false | true  | true  | false
      true  | false | true  | false | true  | false | false | false
      true  | false | true  | false | true  | false | true  | false
      true  | false | true  | false | true  | true  | false | false
      true  | false | true  | false | true  | true  | true  | false
      true  | false | true  | true  | false | false | false | false
      true  | false | true  | true  | false | false | true  | false
      true  | false | true  | true  | false | true  | false | false
      true  | false | true  | true  | false | true  | true  | false
      true  | false | true  | true  | true  | false | false | false
      true  | false | true  | true  | true  | false | true  | false
      true  | false | true  | true  | true  | true  | false | false
      true  | false | true  | true  | true  | true  | true  | false
      true  | true  | false | false | false | false | false | false
      true  | true  | false | false | false | false | true  | false
      true  | true  | false | false | false | true  | false | false
      true  | true  | false | false | false | true  | true  | false
      true  | true  | false | false | true  | false | false | false
      true  | true  | false | false | true  | false | true  | false
      true  | true  | false | false | true  | true  | false | false
      true  | true  | false | false | true  | true  | true  | false
      true  | true  | false | true  | false | false | false | false
      true  | true  | false | true  | false | false | true  | false
      true  | true  | false | true  | false | true  | false | false
      true  | true  | false | true  | false | true  | true  | false
      true  | true  | false | true  | true  | false | false | false
      true  | true  | false | true  | true  | false | true  | false
      true  | true  | false | true  | true  | true  | false | false
      true  | true  | false | true  | true  | true  | true  | false
      true  | true  | true  | false | false | false | false | false
      true  | true  | true  | false | false | false | true  | false
      true  | true  | true  | false | false | true  | false | false
      true  | true  | true  | false | false | true  | true  | false
      true  | true  | true  | false | true  | false | false | false
      true  | true  | true  | false | true  | false | true  | false
      true  | true  | true  | false | true  | true  | false | false
      true  | true  | true  | false | true  | true  | true  | true
      true  | true  | true  | true  | false | false | false | false
      true  | true  | true  | true  | false | false | true  | false
      true  | true  | true  | true  | false | true  | false | false
      true  | true  | true  | true  | false | true  | true  | false
      true  | true  | true  | true  | true  | false | false | false
      true  | true  | true  | true  | true  | false | true  | false
      true  | true  | true  | true  | true  | true  | false | false
      true  | true  | true  | true  | true  | true  | true  | false
    end

    with_them do
      before do
        allow(helper).to receive(:current_user).and_return(user)
        allow(Gitlab).to receive(:com?).and_return(com)
        stub_config(registry: { enabled: config_registry })
        allow(project).to receive(:feature_available?).with(:container_registry, user).and_return(project_registry)
        stub_application_setting(container_expiration_policies_enable_historic_entries: historic_entries)
        stub_feature_flags(container_expiration_policies_historic_entry: false)
        stub_feature_flags(container_expiration_policies_historic_entry: project) if historic_entry

        project.container_expiration_policy.destroy! if nil_policy
        container_repository.update!(project_id: project.id) if container_repositories_exist
      end

      it { is_expected.to eq(expected_result) }
    end
  end
end
