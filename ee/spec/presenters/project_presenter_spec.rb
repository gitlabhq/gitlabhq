# frozen_string_literal: true

require 'spec_helper'

describe ProjectPresenter do
  include Gitlab::Routing.url_helpers

  let(:user) { create(:user) }

  describe '#extra_statistics_anchors' do
    let(:project) { create(:project) }
    let(:pipeline) { create(:ci_pipeline, project: project) }
    let(:presenter) { described_class.new(project, current_user: user) }

    let(:security_dashboard_data) do
      OpenStruct.new(enabled: true,
                     label: _('Security Dashboard'),
                     link: project_security_dashboard_path(project))
    end

    before do
      allow(Ability).to receive(:allowed?).with(user, :read_project_security_dashboard, project).and_return(true)
      allow(project).to receive(:latest_pipeline_with_security_reports).and_return(pipeline)
    end

    it 'contains security dasbhoard link' do
      expect(presenter.extra_statistics_anchors).to include(security_dashboard_data)
    end

    context 'user not signed in' do
      let(:user) { nil }

      before do
        allow(Ability).to receive(:allowed?).with(nil, :read_project_security_dashboard, project).and_return(false)
      end

      it 'has no security dasbhoard link' do
        expect(presenter.extra_statistics_anchors).not_to include(security_dashboard_data)
      end
    end

    context 'user is not allowed to read security dashboard' do
      before do
        allow(Ability).to receive(:allowed?).with(user, :read_project_security_dashboard, project).and_return(false)
      end

      it 'has no security dasbhoard link' do
        expect(presenter.extra_statistics_anchors).not_to include(security_dashboard_data)
      end
    end

    context 'no pipeline having security reports' do
      before do
        allow(project).to receive(:latest_pipeline_with_security_reports).and_return(nil)
      end

      it 'has no security dasbhoard link' do
        expect(presenter.extra_statistics_anchors).not_to include(security_dashboard_data)
      end
    end
  end
end
