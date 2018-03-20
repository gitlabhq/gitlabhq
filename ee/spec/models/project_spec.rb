require 'spec_helper'

describe Project do
  include ExternalAuthorizationServiceHelpers
  using RSpec::Parameterized::TableSyntax

  describe 'associations' do
    it { is_expected.to delegate_method(:shared_runners_minutes).to(:statistics) }
    it { is_expected.to delegate_method(:shared_runners_seconds).to(:statistics) }
    it { is_expected.to delegate_method(:shared_runners_seconds_last_reset).to(:statistics) }

    it { is_expected.to delegate_method(:actual_shared_runners_minutes_limit).to(:shared_runners_limit_namespace) }
    it { is_expected.to delegate_method(:shared_runners_minutes_limit_enabled?).to(:shared_runners_limit_namespace) }
    it { is_expected.to delegate_method(:shared_runners_minutes_used?).to(:shared_runners_limit_namespace) }

    it { is_expected.to have_one(:mirror_data).class_name('ProjectMirrorData') }
    it { is_expected.to have_one(:repository_state).class_name('ProjectRepositoryState').inverse_of(:project) }

    it { is_expected.to have_many(:path_locks) }
    it { is_expected.to have_many(:sourced_pipelines) }
    it { is_expected.to have_many(:source_pipelines) }
    it { is_expected.to have_many(:audit_events).dependent(false) }
  end

  describe 'validations' do
    let(:project) { build(:project) }

    describe 'variables' do
      let(:first_variable) { build(:ci_variable, key: 'test_key', value: 'first', environment_scope: 'prod', project: project) }
      let(:second_variable) { build(:ci_variable, key: 'test_key', value: 'other', environment_scope: 'other', project: project) }

      before do
        project.variables << first_variable
        project.variables << second_variable
      end

      context 'with duplicate variables with same environment scope' do
        before do
          project.variables.last.environment_scope = project.variables.first.environment_scope
        end

        it { expect(project).not_to be_valid }
      end

      context 'with same variable keys and different environment scope' do
        it { expect(project).to be_valid }
      end
    end
  end

  describe '.mirrors_to_sync' do
    let(:timestamp) { Time.now }

    context 'when mirror is scheduled' do
      it 'returns empty' do
        create(:project, :mirror, :import_scheduled)

        expect(described_class.mirrors_to_sync(timestamp)).to be_empty
      end
    end

    context 'when mirror is started' do
      it 'returns empty' do
        create(:project, :mirror, :import_scheduled)

        expect(described_class.mirrors_to_sync(timestamp)).to be_empty
      end
    end

    context 'when mirror is finished' do
      let!(:project) { create(:project, :mirror, :import_finished) }

      it 'returns project if next_execution_timestamp is not in the future' do
        expect(described_class.mirrors_to_sync(timestamp)).to match_array(project)
      end

      it 'returns empty if next_execution_timestamp is in the future' do
        project.mirror_data.update_attributes(next_execution_timestamp: timestamp + 2.minutes)

        expect(described_class.mirrors_to_sync(timestamp)).to be_empty
      end
    end

    context 'when project is failed' do
      let!(:project) { create(:project, :mirror, :import_failed) }

      it 'returns project if next_execution_timestamp is not in the future' do
        expect(described_class.mirrors_to_sync(timestamp)).to match_array(project)
      end

      it 'returns empty if next_execution_timestamp is in the future' do
        project.mirror_data.update_attributes(next_execution_timestamp: timestamp + 2.minutes)

        expect(described_class.mirrors_to_sync(timestamp)).to be_empty
      end

      context 'with retry limit exceeded' do
        let!(:project) { create(:project, :mirror, :import_hard_failed) }

        it 'returns empty' do
          expect(described_class.mirrors_to_sync(timestamp)).to be_empty
        end
      end
    end
  end

  describe '#ensure_external_webhook_token' do
    let(:project) { create(:project, :repository) }

    it "sets external_webhook_token when it's missing" do
      project.update_attribute(:external_webhook_token, nil)
      expect(project.external_webhook_token).to be_blank

      project.ensure_external_webhook_token
      expect(project.external_webhook_token).to be_present
    end
  end

  describe 'hard failing a mirror' do
    it 'sends a notification' do
      project = create(:project, :mirror, :import_started)
      project.mirror_data.update_attributes(retry_count: Gitlab::Mirror::MAX_RETRY)

      expect_any_instance_of(EE::NotificationService).to receive(:mirror_was_hard_failed).with(project)

      project.import_fail
    end
  end

  describe '#push_rule' do
    let(:project) { create(:project, push_rule: create(:push_rule)) }

    subject(:push_rule) { project.push_rule(true) }

    it { is_expected.not_to be_nil }

    context 'push rules unlicensed' do
      before do
        stub_licensed_features(push_rules: false)
      end

      it { is_expected.to be_nil }
    end
  end

  describe "#execute_hooks" do
    context "group hooks" do
      let(:group) { create(:group) }
      let(:project) { create(:project, namespace: group) }
      let(:group_hook) { create(:group_hook, group: group, push_events: true) }

      it 'executes the hook when the feature is enabled' do
        stub_licensed_features(group_webhooks: true)

        fake_service = double
        expect(WebHookService).to receive(:new)
                                    .with(group_hook, { some: 'info' }, 'push_hooks') { fake_service }
        expect(fake_service).to receive(:async_execute)

        project.execute_hooks(some: 'info')
      end

      it 'does not execute the hook when the feature is disabled' do
        stub_licensed_features(group_webhooks: false)

        expect(WebHookService).not_to receive(:new)
                                        .with(group_hook, { some: 'info' }, 'push_hooks')

        project.execute_hooks(some: 'info')
      end
    end
  end

  describe '#execute_hooks' do
    it "triggers project and group hooks" do
      group = create :group, name: 'gitlab'
      project = create(:project, name: 'gitlabhq', namespace: group)
      project_hook = create(:project_hook, push_events: true, project: project)
      group_hook = create(:group_hook, push_events: true, group: group)

      stub_request(:post, project_hook.url)
      stub_request(:post, group_hook.url)

      expect_any_instance_of(GroupHook).to receive(:async_execute).and_return(true)
      expect_any_instance_of(ProjectHook).to receive(:async_execute).and_return(true)

      project.execute_hooks({}, :push_hooks)
    end
  end

  describe '#allowed_to_share_with_group?' do
    let(:project) { create(:project) }

    it "returns true" do
      expect(project.allowed_to_share_with_group?).to be_truthy
    end

    it "returns false" do
      project.namespace.update(share_with_group_lock: true)
      expect(project.allowed_to_share_with_group?).to be_falsey
    end
  end

  describe '#feature_available?' do
    let(:namespace) { build_stubbed(:namespace) }
    let(:project) { build_stubbed(:project, namespace: namespace) }
    let(:user) { build_stubbed(:user) }

    subject { project.feature_available?(feature, user) }

    context 'when feature symbol is included on Namespace features code' do
      before do
        stub_application_setting('check_namespace_plan?' => check_namespace_plan)
        allow(Gitlab).to receive(:com?) { true }
        stub_licensed_features(feature => allowed_on_global_license)
        allow(namespace).to receive(:plan) { plan_license }
      end

      License::EEU_FEATURES.each do |feature_sym|
        let(:feature) { feature_sym }

        context feature_sym.to_s do
          unless License::GLOBAL_FEATURES.include?(feature_sym)
            context "checking #{feature_sym} availability both on Global and Namespace license" do
              let(:check_namespace_plan) { true }

              context 'allowed by Plan License AND Global License' do
                let(:allowed_on_global_license) { true }
                let(:plan_license) { create(:gold_plan) }

                it 'returns true' do
                  is_expected.to eq(true)
                end
              end

              context 'not allowed by Plan License but project and namespace are public' do
                let(:allowed_on_global_license) { true }
                let(:plan_license) { create(:bronze_plan) }

                it 'returns true' do
                  allow(namespace).to receive(:public?) { true }
                  allow(project).to receive(:public?) { true }

                  is_expected.to eq(true)
                end
              end

              unless License.plan_includes_feature?(License::STARTER_PLAN, feature_sym)
                context 'not allowed by Plan License' do
                  let(:allowed_on_global_license) { true }
                  let(:plan_license) { create(:bronze_plan) }

                  it 'returns false' do
                    is_expected.to eq(false)
                  end
                end
              end

              context 'not allowed by Global License' do
                let(:allowed_on_global_license) { false }
                let(:plan_license) { create(:gold_plan) }

                it 'returns false' do
                  is_expected.to eq(false)
                end
              end
            end
          end

          context "when checking #{feature_sym} only for Global license" do
            let(:check_namespace_plan) { false }

            context 'allowed by Global License' do
              let(:allowed_on_global_license) { true }

              it 'returns true' do
                is_expected.to eq(true)
              end
            end

            context 'not allowed by Global License' do
              let(:allowed_on_global_license) { false }

              it 'returns false' do
                is_expected.to eq(false)
              end
            end
          end
        end
      end
    end

    it 'only loads licensed availability once' do
      expect(project).to receive(:load_licensed_feature_available)
                             .once.and_call_original

      2.times { project.feature_available?(:service_desk) }
    end

    context 'when feature symbol is not included on Namespace features code' do
      let(:feature) { :issues }

      it 'checks availability of licensed feature' do
        expect(project.project_feature).to receive(:feature_available?).with(feature, user)

        subject
      end
    end
  end

  describe '#force_import_job!' do
    it 'sets next execution timestamp to now and schedules UpdateAllMirrorsWorker' do
      timestamp = Time.now
      project = create(:project, :mirror)

      expect(UpdateAllMirrorsWorker).to receive(:perform_async)

      Timecop.freeze(timestamp) do
        expect { project.force_import_job! }.to change(project.mirror_data, :next_execution_timestamp).to(timestamp)
      end
    end

    context 'when mirror is hard failed' do
      it 'resets retry count and schedules a mirroring worker' do
        timestamp = Time.now
        project = create(:project, :mirror, :import_hard_failed)

        expect(UpdateAllMirrorsWorker).to receive(:perform_async)

        Timecop.freeze(timestamp) do
          expect { project.force_import_job! }.to change(project.mirror_data, :retry_count).to(0)
          expect(project.mirror_data.next_execution_timestamp).to eq(timestamp)
        end
      end
    end
  end

  describe '#fetch_mirror' do
    where(:import_url, :auth_method, :expected) do
      'http://foo:bar@example.com' | 'password'       | 'http://foo:bar@example.com'
      'ssh://foo:bar@example.com'  | 'password'       | 'ssh://foo:bar@example.com'
      'ssh://foo:bar@example.com'  | 'ssh_public_key' | 'ssh://foo@example.com'
    end

    with_them do
      let(:project) { build(:project, :mirror, import_url: import_url, import_data_attributes: { auth_method: auth_method } ) }

      it do
        expect(project.repository).to receive(:fetch_upstream).with(expected)

        project.fetch_mirror
      end
    end
  end

  describe 'updating import_url' do
    it 'removes previous remote' do
      project = create(:project, :repository, :mirror)

      expect(RepositoryRemoveRemoteWorker).to receive(:perform_async).with(project.id, ::Repository::MIRROR_REMOTE).and_call_original

      project.update_attributes(import_url: "http://test.com")
    end
  end

  describe '#mirror_waiting_duration' do
    it 'returns in seconds the time spent in the queue' do
      project = create(:project, :mirror, :import_scheduled)
      mirror_data = project.mirror_data

      mirror_data.update_attributes(last_update_started_at: mirror_data.last_update_scheduled_at + 5.minutes)

      expect(project.mirror_waiting_duration).to eq(300)
    end
  end

  describe '#mirror_update_duration' do
    it 'returns in seconds the time spent updating' do
      project = create(:project, :mirror, :import_started)

      project.update_attributes(mirror_last_update_at: project.mirror_data.last_update_started_at + 5.minutes)

      expect(project.mirror_update_duration).to eq(300)
    end
  end

  describe '#mirror_about_to_update?' do
    context 'when mirror is expected to run soon' do
      it 'returns true' do
        timestamp = Time.now
        project = create(:project, :mirror, :import_finished, :repository)
        project.mirror_last_update_at = timestamp - 3.minutes
        project.mirror_data.next_execution_timestamp = timestamp - 2.minutes

        expect(project.mirror_about_to_update?).to be true
      end
    end

    context 'when mirror was scheduled' do
      it 'returns false' do
        project = create(:project, :mirror, :import_scheduled, :repository)

        expect(project.mirror_about_to_update?).to be false
      end
    end

    context 'when mirror is hard_failed' do
      it 'returns false' do
        project = create(:project, :mirror, :import_hard_failed)

        expect(project.mirror_about_to_update?).to be false
      end
    end
  end

  describe '#import_in_progress?' do
    let(:traits) { [] }
    let(:project) { create(:project, *traits, import_url: Project::UNKNOWN_IMPORT_URL) }

    shared_examples 'import in progress' do
      context 'when project is a mirror' do
        before do
          traits << :mirror
        end

        context 'when repository is empty' do
          it 'returns true' do
            expect(project.import_in_progress?).to be_truthy
          end
        end

        context 'when repository is not empty' do
          before do
            traits << :repository
          end

          it 'returns false' do
            expect(project.import_in_progress?).to be_falsey
          end
        end
      end

      context 'when project is not a mirror' do
        it 'returns true' do
          expect(project.import_in_progress?).to be_truthy
        end
      end
    end

    context 'when import status is scheduled' do
      before do
        traits << :import_scheduled
      end

      it_behaves_like 'import in progress'
    end

    context 'when import status is started' do
      before do
        traits << :import_started
      end

      it_behaves_like 'import in progress'
    end

    context 'when import status is finished' do
      before do
        traits << :import_finished
      end

      it 'returns false' do
        expect(project.import_in_progress?).to be_falsey
      end
    end
  end

  describe  '#updating_mirror?' do
    context 'when repository is empty' do
      it 'returns false' do
        project = create(:project, :mirror, :import_started)

        expect(project.updating_mirror?).to be false
      end
    end

    context 'when project is not a mirror' do
      it 'returns false' do
        project = create(:project, :import_started)

        expect(project.updating_mirror?).to be false
      end
    end

    context 'when mirror is started' do
      it 'returns true' do
        project = create(:project, :mirror, :import_started, :repository)

        expect(project.updating_mirror?).to be true
      end
    end

    context 'when mirror is scheduled' do
      it 'returns true' do
        project = create(:project, :mirror, :import_scheduled, :repository)

        expect(project.updating_mirror?).to be true
      end
    end
  end

  describe '#mirror_last_update_status' do
    let(:project) { create(:project, :mirror) }

    context 'when mirror has not updated' do
      it 'returns nil' do
        expect(project.mirror_last_update_status).to be_nil
      end
    end

    context 'when mirror has updated' do
      let(:timestamp) { Time.now }

      before do
        project.mirror_last_update_at = timestamp
      end

      context 'when last update time equals the time of the last successful update' do
        it 'returns success' do
          project.mirror_last_successful_update_at = timestamp

          expect(project.mirror_last_update_status).to eq(:success)
        end
      end

      context 'when last update time does not equal the time of the last successful update' do
        it 'returns failed' do
          project.mirror_last_successful_update_at = Time.now - 1.minute

          expect(project.mirror_last_update_status).to eq(:failed)
        end
      end
    end
  end

  describe '#has_remote_mirror?' do
    let(:project) { create(:project, :remote_mirror, :import_started) }
    subject { project.has_remote_mirror? }

    before do
      allow_any_instance_of(RemoteMirror).to receive(:refresh_remote)
    end

    it 'returns true when a remote mirror is enabled' do
      is_expected.to be_truthy
    end

    it 'returns false when unlicensed' do
      stub_licensed_features(repository_mirrors: false)

      is_expected.to be_falsy
    end

    it 'returns false when remote mirror is disabled' do
      project.remote_mirrors.first.update_attributes(enabled: false)

      is_expected.to be_falsy
    end
  end

  describe '#update_remote_mirrors' do
    let(:project) { create(:project, :remote_mirror, :import_started) }
    delegate :update_remote_mirrors, to: :project

    before do
      allow_any_instance_of(RemoteMirror).to receive(:refresh_remote)
    end

    it 'syncs enabled remote mirror' do
      expect_any_instance_of(RemoteMirror).to receive(:sync)

      update_remote_mirrors
    end

    it 'does nothing when remote mirror is disabled globally and not overridden' do
      stub_application_setting(mirror_available: false)
      project.remote_mirror_available_overridden = false

      expect_any_instance_of(RemoteMirror).not_to receive(:sync)

      update_remote_mirrors
    end

    it 'does nothing when unlicensed' do
      stub_licensed_features(repository_mirrors: false)

      expect_any_instance_of(RemoteMirror).not_to receive(:sync)

      update_remote_mirrors
    end

    it 'does not sync disabled remote mirrors' do
      project.remote_mirrors.first.update_attributes(enabled: false)

      expect_any_instance_of(RemoteMirror).not_to receive(:sync)

      update_remote_mirrors
    end
  end

  describe '#any_runners_limit' do
    let(:project) { create(:project, shared_runners_enabled: shared_runners_enabled) }
    let(:specific_runner) { create(:ci_runner) }
    let(:shared_runner) { create(:ci_runner, :shared) }

    context 'for shared runners enabled' do
      let(:shared_runners_enabled) { true }

      before do
        shared_runner
      end

      it 'has a shared runner' do
        expect(project.any_runners?).to be_truthy
      end

      it 'checks the presence of shared runner' do
        expect(project.any_runners? { |runner| runner == shared_runner }).to be_truthy
      end

      context 'with used pipeline minutes' do
        let(:namespace) { create(:namespace, :with_used_build_minutes_limit) }
        let(:project) do
          create(:project,
            namespace: namespace,
            shared_runners_enabled: shared_runners_enabled)
        end

        it 'does not have a shared runner' do
          expect(project.any_runners?).to be_falsey
        end
      end
    end
  end

  describe '#shared_runners_available?' do
    subject { project.shared_runners_available? }

    context 'with used pipeline minutes' do
      let(:namespace) { create(:namespace, :with_used_build_minutes_limit) }
      let(:project) do
        create(:project,
          namespace: namespace,
          shared_runners_enabled: true)
      end

      before do
        expect(namespace).to receive(:shared_runners_minutes_used?).and_call_original
      end

      it 'shared runners are not available' do
        expect(project.shared_runners_available?).to be_falsey
      end
    end
  end

  describe '#shared_runners_limit_namespace' do
    set(:root_ancestor) { create(:group) }
    set(:group) { create(:group, parent: root_ancestor) }
    let(:project) { create(:project, namespace: group) }

    subject { project.shared_runners_limit_namespace }

    context 'when shared_runner_minutes_on_root_namespace is disabled' do
      before do
        stub_feature_flags(shared_runner_minutes_on_root_namespace: false)
      end

      it 'returns parent namespace' do
        is_expected.to eq(group)
      end
    end

    context 'when shared_runner_minutes_on_root_namespace is enabled', :nested_groups do
      before do
        stub_feature_flags(shared_runner_minutes_on_root_namespace: true)
      end

      it 'returns root namespace' do
        is_expected.to eq(root_ancestor)
      end
    end
  end

  describe '#shared_runners_minutes_limit_enabled?' do
    let(:project) { create(:project) }

    subject { project.shared_runners_minutes_limit_enabled? }

    before do
      allow(project.namespace).to receive(:shared_runners_minutes_limit_enabled?)
        .and_return(true)
    end

    context 'with shared runners enabled' do
      before do
        project.shared_runners_enabled = true
      end

      context 'for public project' do
        before do
          project.visibility_level = Project::PUBLIC
        end

        it { is_expected.to be_falsey }
      end

      context 'for internal project' do
        before do
          project.visibility_level = Project::INTERNAL
        end

        it { is_expected.to be_truthy }
      end

      context 'for private project' do
        before do
          project.visibility_level = Project::INTERNAL
        end

        it { is_expected.to be_truthy }
      end
    end

    context 'without shared runners' do
      before do
        project.shared_runners_enabled = false
      end

      it { is_expected.to be_falsey }
    end
  end

  describe '#size_limit_enabled?' do
    let(:project) { create(:project) }

    context 'when repository_size_limit is not configured' do
      it 'is disabled' do
        expect(project.size_limit_enabled?).to be_falsey
      end
    end

    context 'when repository_size_limit is configured' do
      before do
        project.update_attributes(repository_size_limit: 1024)
      end

      context 'with an EES license' do
        let!(:license) { create(:license, plan: License::STARTER_PLAN) }

        it 'is enabled' do
          expect(project.size_limit_enabled?).to be_truthy
        end
      end

      context 'with an EEP license' do
        let!(:license) { create(:license, plan: License::PREMIUM_PLAN) }

        it 'is enabled' do
          expect(project.size_limit_enabled?).to be_truthy
        end
      end

      context 'without a License' do
        before do
          License.destroy_all
        end

        it 'is disabled' do
          expect(project.size_limit_enabled?).to be_falsey
        end
      end
    end
  end

  describe '#service_desk_enabled?' do
    let!(:license) { create(:license, plan: License::PREMIUM_PLAN) }
    let(:namespace) { create(:namespace) }

    subject(:project) { build(:project, :private, namespace: namespace, service_desk_enabled: true) }

    before do
      allow(::Gitlab).to receive(:com?).and_return(true)
      allow(::Gitlab::IncomingEmail).to receive(:enabled?).and_return(true)
      allow(::Gitlab::IncomingEmail).to receive(:supports_wildcard?).and_return(true)
    end

    it 'is enabled' do
      expect(project.service_desk_enabled?).to be_truthy
      expect(project.service_desk_enabled).to be_truthy
    end

    context 'namespace plans active' do
      before do
        stub_application_setting(check_namespace_plan: true)
      end

      it 'is disabled' do
        expect(project.service_desk_enabled?).to be_falsy
        expect(project.service_desk_enabled).to be_falsy
      end

      context 'Service Desk available in namespace plan' do
        let(:namespace) { create(:namespace, plan: :silver_plan) }

        it 'is enabled' do
          expect(project.service_desk_enabled?).to be_truthy
          expect(project.service_desk_enabled).to be_truthy
        end
      end
    end
  end

  describe '#service_desk_address' do
    let(:project) { create(:project, service_desk_enabled: true) }

    before do
      allow(::EE::Gitlab::ServiceDesk).to receive(:enabled?).and_return(true)
      allow(Gitlab.config.incoming_email).to receive(:enabled).and_return(true)
      allow(Gitlab.config.incoming_email).to receive(:address).and_return("test+%{key}@mail.com")
    end

    it 'uses project full path as service desk address key' do
      expect(project.service_desk_address).to eq("test+#{project.full_path}@mail.com")
    end
  end

  describe '#secret_variables_for' do
    let(:project) { create(:project) }

    let!(:secret_variable) do
      create(:ci_variable, value: 'secret', project: project)
    end

    let!(:protected_variable) do
      create(:ci_variable, :protected, value: 'protected', project: project)
    end

    subject { project.secret_variables_for(ref: 'ref') }

    before do
      stub_application_setting(
        default_branch_protection: Gitlab::Access::PROTECTION_NONE)
    end

    context 'when environment is specified' do
      let(:environment) { create(:environment, name: 'review/name') }

      subject do
        project.secret_variables_for(ref: 'ref', environment: environment)
      end

      shared_examples 'matching environment scope' do
        context 'when variable environment scope is available' do
          before do
            stub_licensed_features(variable_environment_scope: true)
          end

          it 'contains the secret variable' do
            is_expected.to contain_exactly(secret_variable)
          end
        end

        context 'when variable environment scope is unavailable' do
          before do
            stub_licensed_features(variable_environment_scope: false)
          end

          it 'does not contain the secret variable' do
            is_expected.not_to contain_exactly(secret_variable)
          end
        end
      end

      shared_examples 'not matching environment scope' do
        context 'when variable environment scope is available' do
          before do
            stub_licensed_features(variable_environment_scope: true)
          end

          it 'does not contain the secret variable' do
            is_expected.not_to contain_exactly(secret_variable)
          end
        end

        context 'when variable environment scope is unavailable' do
          before do
            stub_licensed_features(variable_environment_scope: false)
          end

          it 'does not contain the secret variable' do
            is_expected.not_to contain_exactly(secret_variable)
          end
        end
      end

      context 'when environment scope is exactly matched' do
        before do
          secret_variable.update(environment_scope: 'review/name')
        end

        it_behaves_like 'matching environment scope'
      end

      context 'when environment scope is matched by wildcard' do
        before do
          secret_variable.update(environment_scope: 'review/*')
        end

        it_behaves_like 'matching environment scope'
      end

      context 'when environment scope does not match' do
        before do
          secret_variable.update(environment_scope: 'review/*/special')
        end

        it_behaves_like 'not matching environment scope'
      end

      context 'when environment scope has _' do
        before do
          stub_licensed_features(variable_environment_scope: true)
        end

        it 'does not treat it as wildcard' do
          secret_variable.update(environment_scope: '*_*')

          is_expected.not_to contain_exactly(secret_variable)
        end

        it 'matches literally for _' do
          secret_variable.update(environment_scope: 'foo_bar/*')
          environment.update(name: 'foo_bar/test')

          is_expected.to contain_exactly(secret_variable)
        end
      end

      # The environment name and scope cannot have % at the moment,
      # but we're considering relaxing it and we should also make sure
      # it doesn't break in case some data sneaked in somehow as we're
      # not checking this integrity in database level.
      context 'when environment scope has %' do
        before do
          stub_licensed_features(variable_environment_scope: true)
        end

        it 'does not treat it as wildcard' do
          secret_variable.update_attribute(:environment_scope, '*%*')

          is_expected.not_to contain_exactly(secret_variable)
        end

        it 'matches literally for _' do
          secret_variable.update(environment_scope: 'foo%bar/*')
          environment.update_attribute(:name, 'foo%bar/test')

          is_expected.to contain_exactly(secret_variable)
        end
      end

      context 'when variables with the same name have different environment scopes' do
        let!(:partially_matched_variable) do
          create(:ci_variable,
                 key: secret_variable.key,
                 value: 'partial',
                 environment_scope: 'review/*',
                 project: project)
        end

        let!(:perfectly_matched_variable) do
          create(:ci_variable,
                 key: secret_variable.key,
                 value: 'prefect',
                 environment_scope: 'review/name',
                 project: project)
        end

        before do
          stub_licensed_features(variable_environment_scope: true)
        end

        it 'puts variables matching environment scope more in the end' do
          is_expected.to eq(
            [secret_variable,
             partially_matched_variable,
             perfectly_matched_variable])
        end
      end
    end
  end

  describe '#approvals_before_merge' do
    where(:license_value, :db_value, :expected) do
      true  | 5 | 5
      true  | 0 | 0
      false | 5 | 0
      false | 0 | 0
    end

    with_them do
      let(:project) { build(:project, approvals_before_merge: db_value) }

      subject { project.approvals_before_merge }

      before do
        stub_licensed_features(merge_request_approvers: license_value)
      end

      it { is_expected.to eq(expected) }
    end
  end

  describe "#reset_approvals_on_push?" do
    where(:license_value, :db_value, :expected) do
      true  | true  | true
      true  | false | false
      false | true  | false
      false | false | false
    end

    with_them do
      let(:project) { build(:project, reset_approvals_on_push: db_value) }

      subject { project.reset_approvals_on_push? }

      before do
        stub_licensed_features(merge_request_approvers: license_value)
      end

      it { is_expected.to eq(expected) }
    end
  end

  describe '#approvals_before_merge' do
    where(:license_value, :db_value, :expected) do
      true  | 5 | 5
      true  | 0 | 0
      false | 5 | 0
      false | 0 | 0
    end

    with_them do
      let(:project) { build(:project, approvals_before_merge: db_value) }

      subject { project.approvals_before_merge }

      before do
        stub_licensed_features(merge_request_approvers: license_value)
      end

      it { is_expected.to eq(expected) }
    end
  end

  describe '#rename_repo' do
    context 'when running on a primary node' do
      set(:primary) { create(:geo_node, :primary) }
      set(:secondary) { create(:geo_node) }
      let(:project) { create(:project, :repository, :legacy_storage) }
      let(:gitlab_shell) { Gitlab::Shell.new }

      it 'logs the Geo::RepositoryRenamedEvent for project backed by hashed storage' do
        project_hashed_storage = create(:project)

        allow(project_hashed_storage).to receive(:gitlab_shell).and_return(gitlab_shell)
        allow(project_hashed_storage).to receive(:previous_changes).and_return('path' => ['foo'])
        allow(gitlab_shell).to receive(:mv_repository).twice.and_return(true)

        expect { project_hashed_storage.rename_repo }.to change(Geo::RepositoryRenamedEvent, :count)
      end

      it 'logs the Geo::RepositoryRenamedEvent for project backed by legacy storage' do
        allow(project).to receive(:gitlab_shell).and_return(gitlab_shell)
        allow(project).to receive(:previous_changes).and_return('path' => ['foo'])
        allow(gitlab_shell).to receive(:mv_repository).twice.and_return(true)

        expect(Geo::RepositoryRenamedEventStore).to receive(:new)
          .with(instance_of(described_class), old_path: 'foo', old_path_with_namespace: "#{project.namespace.full_path}/foo")
          .and_call_original

        expect { project.rename_repo }.to change(Geo::RepositoryRenamedEvent, :count).by(1)
      end
    end
  end

  shared_examples 'project with disabled services' do
    it 'has some disabled services' do
      stub_const('License::ANY_PLAN_FEATURES', [])

      expect(project.disabled_services).to match_array(disabled_services)
    end
  end

  shared_examples 'project without disabled services' do
    it 'has some disabled services' do
      expect(project.disabled_services).to be_empty
    end
  end

  describe '#disabled_services' do
    let(:namespace) { create(:group, :private) }
    let(:project) { create(:project, :private, namespace: namespace) }
    let(:disabled_services) { %w(jenkins jenkins_deprecated github) }

    context 'without a license key' do
      before do
        License.destroy_all
      end

      it_behaves_like 'project with disabled services'
    end

    context 'with a license key' do
      before do
        allow_any_instance_of(License).to receive(:plan).and_return(License::PREMIUM_PLAN)
      end

      context 'when checking of namespace plan is enabled' do
        before do
          stub_application_setting_on_object(project, should_check_namespace_plan: true)
        end

        context 'and namespace does not have a plan' do
          it_behaves_like 'project with disabled services'
        end

        context 'and namespace has a plan' do
          let(:namespace) { create(:group, :private, plan: :silver_plan) }

          it_behaves_like 'project without disabled services'
        end
      end

      context 'when checking of namespace plan is not enabled' do
        before do
          stub_application_setting_on_object(project, should_check_namespace_plan: false)
        end

        it_behaves_like 'project without disabled services'
      end
    end
  end

  describe '#remote_mirror_available?' do
    let(:project) { create(:project) }

    context 'when remote mirror global setting is enabled' do
      it 'returns true' do
        expect(project.remote_mirror_available?).to be(true)
      end
    end

    context 'when remote mirror global setting is disabled' do
      before do
        stub_application_setting(mirror_available: false)
      end

      it 'returns true when overridden' do
        project.remote_mirror_available_overridden = true

        expect(project.remote_mirror_available?).to be(true)
      end

      it 'returns false when not overridden' do
        expect(project.remote_mirror_available?).to be(false)
      end
    end
  end

  describe '#pull_mirror_available?' do
    let(:project) { create(:project) }

    context 'when mirror global setting is enabled' do
      it 'returns true' do
        expect(project.pull_mirror_available?).to be(true)
      end
    end

    context 'when mirror global setting is disabled' do
      before do
        stub_application_setting(mirror_available: false)
      end

      it 'returns true when overridden' do
        project.pull_mirror_available_overridden = true

        expect(project.pull_mirror_available?).to be(true)
      end

      it 'returns false when not overridden' do
        expect(project.pull_mirror_available?).to be(false)
      end
    end
  end

  describe '#username_only_import_url' do
    where(:import_url, :username, :expected_import_url) do
      '' | 'foo' | ''
      '' | ''    | ''
      '' | nil   | ''

      nil | 'foo' | nil
      nil | ''    | nil
      nil | nil   | nil

      'http://example.com' | 'foo' | 'http://foo@example.com'
      'http://example.com' | ''    | 'http://example.com'
      'http://example.com' | nil   | 'http://example.com'
    end

    with_them do
      let(:project) { build(:project, import_url: import_url, import_data_attributes: { user: username, password: 'password' }) }

      it { expect(project.username_only_import_url).to eq(expected_import_url) }
    end
  end

  describe '#username_only_import_url=' do
    it 'sets the import url and username' do
      project = build(:project, import_url: 'http://user@example.com')

      expect(project.import_url).to eq('http://user@example.com')
      expect(project.import_data.user).to eq('user')
    end

    it 'does not unset the password' do
      project = build(:project, import_url: 'http://olduser:pass@old.example.com')
      project.username_only_import_url = 'http://user@example.com'

      expect(project.username_only_import_url).to eq('http://user@example.com')
      expect(project.import_url).to eq('http://user:pass@example.com')
      expect(project.import_data.password).to eq('pass')
    end

    it 'clears the username if passed the empty string' do
      project = build(:project, import_url: 'http://olduser:pass@old.example.com')
      project.username_only_import_url = ''

      expect(project.username_only_import_url).to eq('')
      expect(project.import_url).to eq('')
      expect(project.import_data.user).to be_nil
      expect(project.import_data.password).to eq('pass')
    end
  end

  describe '#with_slack_application_disabled' do
    it 'returns projects where Slack application is disabled' do
      project1 = create(:project)
      project2 = create(:project)
      create(:gitlab_slack_application_service, project: project2)

      projects = described_class.with_slack_application_disabled

      expect(projects).to include(project1)
      expect(projects).not_to include(project2)
    end
  end

  describe '#external_authorization_classification_label' do
    it 'falls back to the default when none is configured' do
      enable_external_authorization_service

      expect(build(:project).external_authorization_classification_label)
        .to eq('default_label')
    end

    it 'returns `nil` if the feature is disabled' do
      stub_licensed_features(external_authorization_service: false)

      project = build(:project,
                      external_authorization_classification_label: 'hello')

      expect(project.external_authorization_classification_label)
        .to eq(nil)
    end

    it 'returns the classification label if it was configured on the project' do
      enable_external_authorization_service

      project = build(:project,
                      external_authorization_classification_label: 'hello')

      expect(project.external_authorization_classification_label)
        .to eq('hello')
    end

    it 'does not break when not stubbing the license check' do
      enable_external_authorization_service
      enable_namespace_license_check!
      project = build(:project)

      expect { project.external_authorization_classification_label }.not_to raise_error
    end
  end

  describe '#user_can_push_to_empty_repo?' do
    it 'returns false when the external service denies access' do
      user = create(:user)
      project = create(:project)
      project.add_master(user)
      external_service_deny_access(user, project)

      expect(project.user_can_push_to_empty_repo?(user)).to be_falsey
    end
  end

  describe 'project import state transitions' do
    context 'state transition: [:started] => [:finished]' do
      context 'elasticsearch indexing disabled' do
        before do
          stub_ee_application_setting(elasticsearch_indexing: false)
        end

        it 'does not index the repository' do
          project = create(:project, :import_started, import_type: :github)

          expect(ElasticCommitIndexerWorker).not_to receive(:perform_async)

          project.import_finish
        end
      end

      context 'elasticsearch indexing enabled' do
        let(:project) { create(:project, :import_started, import_type: :github) }

        before do
          stub_ee_application_setting(elasticsearch_indexing: true)
        end

        context 'no index status' do
          it 'schedules a full index of the repository' do
            expect(ElasticCommitIndexerWorker).to receive(:perform_async).with(project.id, nil)

            project.import_finish
          end
        end

        context 'with index status' do
          let!(:index_status) { project.create_index_status!(indexed_at: Time.now, last_commit: 'foo') }

          it 'schedules a progressive index of the repository' do
            expect(ElasticCommitIndexerWorker).to receive(:perform_async).with(project.id, index_status.last_commit)

            project.import_finish
          end
        end
      end
    end
  end
end
