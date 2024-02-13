# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AutoDevopsHelper do
  let_it_be(:project, reload: true) { create(:project) }
  let_it_be(:user) { create(:user) }

  describe '.show_auto_devops_callout?' do
    let(:allowed) { true }

    before do
      allow(helper).to receive(:can?).with(user, :admin_pipeline, project) { allowed }
      allow(helper).to receive(:current_user) { user }

      stub_feature_flags(auto_devops_banner_disabled: false)
    end

    subject { helper.show_auto_devops_callout?(project) }

    context 'when auto devops is implicitly enabled' do
      it { is_expected.to eq(false) }
    end

    context 'when auto devops is not implicitly enabled' do
      before do
        Gitlab::CurrentSettings.update!(auto_devops_enabled: false)
      end

      it { is_expected.to eq(true) }
    end

    context 'when the banner is disabled by feature flag' do
      before do
        stub_feature_flags(auto_devops_banner_disabled: true)
      end

      it { is_expected.to be_falsy }
    end

    context 'when dismissed' do
      before do
        helper.request.cookies[:auto_devops_settings_dismissed] = 'true'
      end

      it { is_expected.to eq(false) }
    end

    context 'when user cannot admin project' do
      let(:allowed) { false }

      it { is_expected.to eq(false) }
    end

    context 'when auto devops is enabled system-wide' do
      before do
        stub_application_setting(auto_devops_enabled: true)
      end

      it { is_expected.to eq(false) }
    end

    context 'when auto devops is explicitly enabled for project' do
      before do
        project.create_auto_devops!(enabled: true)
      end

      it { is_expected.to eq(false) }
    end

    context 'when auto devops is explicitly disabled for project' do
      before do
        project.create_auto_devops!(enabled: false)
      end

      it { is_expected.to eq(false) }
    end

    context 'when master contains a .gitlab-ci.yml file' do
      before do
        allow(project).to receive(:has_ci_config_file?).and_return(true)
      end

      it { is_expected.to eq(false) }
    end

    context 'when another service is enabled' do
      before do
        create(:integration, project: project, category: :ci, active: true)
      end

      it { is_expected.to eq(false) }
    end
  end

  describe '#auto_devops_settings_path' do
    it 'returns auto devops settings path' do
      expect(helper.auto_devops_settings_path(project)).to eql(project_settings_ci_cd_path(project, anchor: 'autodevops-settings'))
    end
  end

  describe '#badge_for_auto_devops_scope' do
    subject { helper.badge_for_auto_devops_scope(receiver) }

    context 'when receiver is a group' do
      context 'when explicitly enabled' do
        let(:receiver) { create(:group, :auto_devops_enabled) }

        it { is_expected.to eq('group enabled') }
      end

      context 'when explicitly disabled' do
        let(:receiver) { create(:group, :auto_devops_disabled) }

        it { is_expected.to be_nil }
      end

      context 'when auto devops is implicitly enabled' do
        let(:receiver) { create(:group) }

        context 'by instance' do
          before do
            stub_application_setting(auto_devops_enabled: true)
          end

          it { is_expected.to eq('instance enabled') }
        end

        context 'with groups' do
          before do
            receiver.update!(parent: parent)
          end

          context 'when auto devops is enabled on parent' do
            let(:parent) { create(:group, :auto_devops_enabled) }

            it { is_expected.to eq('group enabled') }
          end

          context 'when auto devops is enabled on parent group' do
            let(:root_parent) { create(:group, :auto_devops_enabled) }
            let(:parent) { create(:group, parent: root_parent) }

            it { is_expected.to eq('group enabled') }
          end

          context 'when auto devops disabled set on parent group' do
            let(:root_parent) { create(:group, :auto_devops_disabled) }
            let(:parent) { create(:group, parent: root_parent) }

            it { is_expected.to be_nil }
          end
        end
      end
    end

    context 'when receiver is a project' do
      context 'when auto devops is enabled at project level' do
        let(:receiver) { create(:project, :auto_devops) }

        it { is_expected.to be_nil }
      end

      context 'when auto devops is disabled at project level' do
        let(:receiver) { create(:project, :auto_devops_disabled) }

        it { is_expected.to be_nil }
      end

      context 'when auto devops is implicitly enabled' do
        let(:receiver) { create(:project) }

        context 'by instance' do
          before do
            stub_application_setting(auto_devops_enabled: true)
          end

          it { is_expected.to eq('instance enabled') }
        end

        context 'with groups' do
          let(:receiver) { create(:project, :repository, namespace: group) }

          before do
            stub_application_setting(auto_devops_enabled: false)
          end

          context 'when auto devops is enabled on group level' do
            let(:group) { create(:group, :auto_devops_enabled) }

            it { is_expected.to eq('group enabled') }
          end

          context 'when auto devops is enabled on root group' do
            let(:root_parent) { create(:group, :auto_devops_enabled) }
            let(:group) { create(:group, parent: root_parent) }

            it { is_expected.to eq('group enabled') }
          end
        end
      end

      context 'when auto devops is implicitly disabled' do
        let(:receiver) { create(:project) }

        context 'by instance' do
          before do
            stub_application_setting(auto_devops_enabled: false)
          end

          it { is_expected.to be_nil }
        end

        context 'with groups' do
          let(:receiver) { create(:project, :repository, namespace: group) }

          context 'when auto devops is disabled on group level' do
            let(:group) { create(:group, :auto_devops_disabled) }

            it { is_expected.to be_nil }
          end

          context 'when root group is enabled and parent disabled' do
            let(:root_parent) { create(:group, :auto_devops_enabled) }
            let(:group) { create(:group, :auto_devops_disabled, parent: root_parent) }

            it { is_expected.to be_nil }
          end
        end
      end
    end
  end
end
