require 'spec_helper'

describe AutoDevopsHelper do
  set(:project) { create(:project) }
  set(:user) { create(:user) }

  describe '.show_auto_devops_callout?' do
    let(:allowed) { true }

    before do
      allow(helper).to receive(:can?).with(user, :admin_pipeline, project) { allowed }
      allow(helper).to receive(:current_user) { user }

      Feature.get(:auto_devops_banner_disabled).disable
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
      it 'allows the feature flag to disable' do
        Feature.get(:auto_devops_banner_disabled).enable

        expect(subject).to be(false)
      end
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
        allow(project.repository).to receive(:gitlab_ci_yml).and_return("script: ['test']")
      end

      it { is_expected.to eq(false) }
    end

    context 'when another service is enabled' do
      before do
        create(:service, project: project, category: :ci, active: true)
      end

      it { is_expected.to eq(false) }
    end
  end
end
