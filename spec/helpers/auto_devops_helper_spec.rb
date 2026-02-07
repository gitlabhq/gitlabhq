# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AutoDevopsHelper do
  let_it_be(:project, reload: true) { create(:project) }
  let_it_be(:user) { create(:user) }

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
