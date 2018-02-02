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

    context 'when all conditions are met' do
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

  describe '.auto_devops_warning_message' do
    subject { helper.auto_devops_warning_message(project) }

    context 'when the service is missing' do
      before do
        allow(helper).to receive(:missing_auto_devops_service?).and_return(true)
      end

      context 'when the domain is missing' do
        before do
          allow(helper).to receive(:missing_auto_devops_domain?).and_return(true)
        end

        it { is_expected.to match(/Auto Review Apps and Auto Deploy need a domain name and a .* to work correctly./) }
      end

      context 'when the domain is not missing' do
        before do
          allow(helper).to receive(:missing_auto_devops_domain?).and_return(false)
        end

        it { is_expected.to match(/Auto Review Apps and Auto Deploy need a .* to work correctly./) }
      end
    end

    context 'when the domain is missing' do
      before do
        allow(helper).to receive(:missing_auto_devops_service?).and_return(false)
        allow(helper).to receive(:missing_auto_devops_domain?).and_return(true)
      end

      it { is_expected.to eq('Auto Review Apps and Auto Deploy need a domain name to work correctly.') }
    end
  end
end
