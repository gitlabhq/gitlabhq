# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PackagesHelper, feature_category: :package_registry do
  using RSpec::Parameterized::TableSyntax
  include AdminModeHelper

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
    let_it_be(:public_project) { create(:project, :public) }

    it 'returns the pypi registry url with token when project is private' do
      url = helper.pypi_registry_url(project)

      expect(url).to eq("#{base_url_with_token}projects/#{project.id}/packages/pypi/simple")
    end

    it 'returns the pypi registry url without token when project is public' do
      url = helper.pypi_registry_url(public_project)

      expect(url).to eq("#{base_url}projects/#{public_project.id}/packages/pypi/simple")
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

  describe '#track_package_event' do
    let_it_be(:project) { create(:project) }

    let(:action) { 'push_package' }
    let(:scope) { :terraform_module }
    let(:category) { described_class.name }
    let(:namespace) { project.namespace }
    let(:user) { project.creator }
    let(:create_event_service) { instance_double(::Packages::CreateEventService) }

    before do
      allow(helper).to receive(:current_user).and_return(user)
      allow(Packages::CreateEventService).to receive(:new).and_return(create_event_service)
      allow(create_event_service).to receive(:execute)
    end

    it 'tracks a snowplow event' do
      helper.track_package_event(action, scope, category: category, namespace: namespace, user: user, project: project)

      expect_snowplow_event(
        category: category,
        action: action,
        user: user,
        project: project,
        namespace: namespace
      )
    end

    it 'calls CreateEventService with correct parameters and executes it' do
      helper.track_package_event(action, scope, category: category, namespace: namespace, user: user, project: project)

      expect(Packages::CreateEventService).to have_received(:new).with(project, user, event_name: action, scope: scope)
      expect(create_event_service).to have_received(:execute)
    end
  end

  describe '#show_cleanup_policy_link' do
    let_it_be(:user) { create(:user) }
    let_it_be_with_reload(:container_repository) { create(:container_repository) }

    subject { helper.show_cleanup_policy_link(project.reload) }

    context 'when user has permission' do
      where(:config_registry, :project_registry, :nil_policy, :container_repositories_exist, :expected_result) do
        false | false | false | false | false
        false | false | false | true  | false
        false | false | true  | false | false
        false | false | true  | true  | false
        false | true  | false | false | false
        false | true  | false | true  | false
        false | true  | true  | false | false
        false | true  | true  | true  | false
        true  | false | false | false | false
        true  | false | false | true  | false
        true  | false | true  | false | false
        true  | false | true  | true  | false
        true  | true  | false | false | false
        true  | true  | false | true  | false
        true  | true  | true  | false | false
        true  | true  | true  | true  | true
      end

      with_them do
        before do
          project.add_owner(user)
          allow(helper).to receive(:current_user).and_return(user)
          stub_config(registry: { enabled: config_registry })
          allow(project).to receive(:feature_available?).with(:container_registry, user).and_return(project_registry)

          project.container_expiration_policy.update!(enabled: true)

          project.container_expiration_policy.destroy! if nil_policy
          container_repository.update!(project_id: project.id) if container_repositories_exist
        end

        it { is_expected.to eq(expected_result) }
      end
    end

    context 'when user does not have permission' do
      before do
        project.add_developer(user)
        allow(helper).to receive(:current_user).and_return(user)
        stub_config(registry: { enabled: true })
        allow(project).to receive(:feature_available?).with(:container_registry, user).and_return(true)

        project.container_expiration_policy.update!(enabled: true)
        container_repository.update!(project_id: project.id)
      end

      it { is_expected.to eq(false) }
    end

    context 'when container expiration policy is disabled' do
      before do
        project.add_owner(user)
        allow(helper).to receive(:current_user).and_return(user)
        stub_config(registry: { enabled: true })
        allow(project).to receive(:feature_available?).with(:container_registry, user).and_return(true)
        container_repository.update!(project_id: project.id)

        project.container_expiration_policy.update!(enabled: false)
      end

      it { is_expected.to eq(true) }
    end
  end

  describe '#show_container_registry_settings' do
    let_it_be(:project) { create(:project) }
    let_it_be(:user) { create(:user) }

    before do
      allow(helper).to receive(:current_user) { user }
    end

    subject { helper.show_container_registry_settings(project) }

    context 'with container registry config enabled' do
      before do
        stub_config(registry: { enabled: true })
      end

      context 'when user has permission' do
        before do
          allow(Ability).to receive(:allowed?).with(user, :admin_container_image, project).and_return(true)
        end

        it { is_expected.to be(true) }
      end

      context 'when user does not have permission' do
        before do
          allow(Ability).to receive(:allowed?).with(user, :admin_container_image, project).and_return(false)
        end

        it { is_expected.to be(false) }
      end
    end

    context 'with container registry config disabled' do
      before do
        stub_config(registry: { enabled: false })
      end

      context 'when user has permission' do
        before do
          allow(Ability).to receive(:allowed?).with(user, :admin_container_image, project).and_return(true)
        end

        it { is_expected.to be(false) }
      end

      context 'when user does not have permission' do
        before do
          allow(Ability).to receive(:allowed?).with(user, :admin_container_image, project).and_return(false)
        end

        it { is_expected.to be(false) }
      end
    end
  end

  describe '#show_group_package_registry_settings' do
    let_it_be(:group) { create(:group) }
    let_it_be(:user) { create(:user) }
    let_it_be(:admin) { create(:admin) }

    before do
      allow(helper).to receive(:current_user) { user }
    end

    subject { helper.show_group_package_registry_settings(group) }

    context 'with package registry config enabled' do
      before do
        stub_config(packages: { enabled: true })
      end

      context "with admin", :enable_admin_mode do
        before do
          allow(helper).to receive(:current_user) { admin }
        end

        it { is_expected.to be(true) }
      end

      context "with owner" do
        before do
          group.add_owner(user)
        end

        it { is_expected.to be(true) }
      end

      %i[maintainer developer reporter guest].each do |role|
        context "with #{role}" do
          before do
            group.public_send("add_#{role}", user)
          end

          it { is_expected.to be(false) }
        end
      end
    end

    context 'with package registry config disabled' do
      before do
        stub_config(packages: { enabled: false })
      end

      context "with admin", :enable_admin_mode do
        before do
          allow(helper).to receive(:current_user) { admin }
        end

        it { is_expected.to be(false) }
      end

      %i[owner maintainer developer reporter guest].each do |role|
        context "with #{role}" do
          before do
            group.public_send("add_#{role}", user)
          end

          it { is_expected.to be(false) }
        end
      end
    end
  end

  describe '#group_packages_template_data' do
    let_it_be(:group) { create(:group) }
    let_it_be(:user) { create(:user) }

    before do
      allow(helper).to receive(:current_user) { user }
      stub_config(packages: { enabled: true })
    end

    subject { helper.group_packages_template_data(group) }

    it 'returns the correct data' do
      is_expected.to include(
        empty_list_illustration: match_asset_path('illustrations/empty-state/empty-package-md.svg'),
        endpoint: group_packages_path(group),
        full_path: group.full_path,
        group_list_url: group_packages_path(group),
        npm_instance_url: package_registry_instance_url(:npm),
        page_type: 'groups',
        project_list_url: ''
      )
    end

    context 'when user has permission' do
      before do
        group.add_owner(user)
      end

      it 'returns the correct data' do
        is_expected.to include(
          can_delete_packages: 'true',
          settings_path: group_settings_packages_and_registries_path(group)
        )
      end
    end

    context 'when user does not have permission' do
      it 'returns the correct data' do
        is_expected.to include(
          can_delete_packages: 'false',
          settings_path: ''
        )
      end
    end
  end

  describe '#project_packages_template_data' do
    let_it_be(:user) { create(:user) }

    subject { helper.project_packages_template_data(project) }

    before do
      allow(helper).to receive(:current_user) { user }
      stub_config(packages: { enabled: true })
    end

    it 'returns the correct data' do
      is_expected.to include(
        empty_list_illustration: match_asset_path('illustrations/empty-state/empty-package-md.svg'),
        endpoint: project_packages_path(project),
        full_path: project.full_path,
        group_list_url: '',
        npm_instance_url: package_registry_instance_url(:npm),
        page_type: 'projects',
        project_list_url: project_packages_path(project)
      )
    end

    context 'when user has permission' do
      before do
        project.add_owner(user)
      end

      it 'returns the correct data' do
        is_expected.to include(
          can_delete_packages: 'true',
          settings_path: project_settings_packages_and_registries_path(project, anchor: 'package-registry-settings')
        )
      end
    end

    context 'when user does not have permission' do
      it 'returns the correct data' do
        is_expected.to include(
          can_delete_packages: 'false',
          settings_path: ''
        )
      end
    end
  end

  describe '#settings_data' do
    let(:user) { build_stubbed(:user) }

    subject { helper.settings_data(project) }

    where(:config_registry, :permission, :supports_gitlab_api?, :expected_result) do
      false | false | false | false
      false | false | true  | false
      false | true  | false | false
      false | true  | true  | false
      true  | false | false | false
      true  | false | true  | false
      true  | true  | false | false
      true  | true  | true  | true
    end

    with_them do
      before do
        allow(helper).to receive(:current_user).and_return(user)
        stub_config(registry: { enabled: config_registry })
        allow(ContainerRegistry::GitlabApiClient).to receive(:supports_gitlab_api?).and_return(supports_gitlab_api?)
        allow(Ability).to receive(:allowed?).and_call_original
        allow(Ability).to receive(:allowed?).with(user, :admin_container_image, project).and_return(permission)
        allow(Ability).to receive(:allowed?).with(user, :admin_package, project).and_return(true)
      end

      it { is_expected.to include(is_container_registry_metadata_database_enabled: expected_result.to_s) }
    end
  end

  describe '#can_delete_packages?' do
    let_it_be(:project) { create(:project) }
    let_it_be(:user) { create(:user) }

    before do
      allow(helper).to receive(:current_user) { user }
    end

    subject { helper.can_delete_packages?(project) }

    context 'with package registry config enabled' do
      before do
        stub_config(packages: { enabled: true })
      end

      context 'when user has permission' do
        before do
          allow(Ability).to receive(:allowed?).with(user, :destroy_package, project).and_return(true)
        end

        it { is_expected.to be(true) }
      end

      context 'when user does not have permission' do
        before do
          allow(Ability).to receive(:allowed?).with(user, :destroy_package, project).and_return(false)
        end

        it { is_expected.to be(false) }
      end
    end

    context 'with package registry config disabled' do
      before do
        stub_config(packages: { enabled: false })
      end

      context 'when user has permission' do
        before do
          allow(Ability).to receive(:allowed?).with(user, :destroy_package, project).and_return(true)
        end

        it { is_expected.to be(false) }
      end

      context 'when user does not have permission' do
        before do
          allow(Ability).to receive(:allowed?).with(user, :destroy_package, project).and_return(false)
        end

        it { is_expected.to be(false) }
      end
    end
  end

  describe '#can_delete_group_packages?' do
    let_it_be(:group) { create(:group) }
    let_it_be(:user) { create(:user) }

    before do
      allow(helper).to receive(:current_user) { user }
    end

    subject { helper.can_delete_group_packages?(group) }

    context 'with package registry config enabled' do
      before do
        stub_config(packages: { enabled: true })
      end

      context 'when user has permission' do
        before do
          allow(Ability).to receive(:allowed?).with(user, :destroy_package, group).and_return(true)
        end

        it { is_expected.to be(true) }
      end

      context 'when user does not have permission' do
        before do
          allow(Ability).to receive(:allowed?).with(user, :destroy_package, group).and_return(false)
        end

        it { is_expected.to be(false) }
      end
    end

    context 'with package registry config disabled' do
      before do
        stub_config(packages: { enabled: false })
      end

      context 'when user has permission' do
        before do
          allow(Ability).to receive(:allowed?).with(user, :destroy_package, group).and_return(true)
        end

        it { is_expected.to be(false) }
      end

      context 'when user does not have permission' do
        before do
          allow(Ability).to receive(:allowed?).with(user, :destroy_package, group).and_return(false)
        end

        it { is_expected.to be(false) }
      end
    end
  end
end
