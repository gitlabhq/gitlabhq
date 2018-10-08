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

    context 'user is allowed to read security dashboard' do
      before do
        allow(Ability).to receive(:allowed?).with(user, :read_project_security_dashboard, project).and_return(true)
      end

      it 'has security dashboard link' do
        expect(presenter.extra_statistics_anchors).to include(security_dashboard_data)
      end
    end

    context 'user is not allowed to read security dashboard' do
      before do
        allow(Ability).to receive(:allowed?).with(user, :read_project_security_dashboard, project).and_return(false)
      end

      it 'has no security dashboard link' do
        expect(presenter.extra_statistics_anchors).not_to include(security_dashboard_data)
      end
    end
  end
end
