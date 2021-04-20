# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::Issues::ServiceDeskHelper do
  let_it_be(:project) { create(:project, :public, service_desk_enabled: true) }

  let(:user) { build_stubbed(:user) }
  let(:current_user) { user }

  describe '#service_desk_meta' do
    subject { helper.service_desk_meta(project) }

    context "when service desk is supported and user can edit project settings" do
      before do
        allow(Gitlab::IncomingEmail).to receive(:enabled?).and_return(true)
        allow(Gitlab::IncomingEmail).to receive(:supports_wildcard?).and_return(true)
        allow(helper).to receive(:current_user).and_return(user)
        allow(helper).to receive(:can?).with(current_user, :admin_project, project).and_return(true)
      end

      it {
        is_expected.to eq({
          is_service_desk_supported: true,
          is_service_desk_enabled: true,
          can_edit_project_settings: true,
          service_desk_address: project.service_desk_address,
          service_desk_help_page: help_page_path('user/project/service_desk'),
          edit_project_page: edit_project_path(project),
          svg_path: ActionController::Base.helpers.image_path('illustrations/service_desk_empty.svg')
        })
      }
    end

    context "when service desk is not supported and user cannot edit project settings" do
      before do
        allow(Gitlab::IncomingEmail).to receive(:enabled?).and_return(false)
        allow(Gitlab::IncomingEmail).to receive(:supports_wildcard?).and_return(false)
        allow(helper).to receive(:current_user).and_return(user)
        allow(helper).to receive(:can?).with(current_user, :admin_project, project).and_return(false)
      end

      it {
        is_expected.to eq({
          is_service_desk_supported: false,
          is_service_desk_enabled: false,
          can_edit_project_settings: false,
          incoming_email_help_page: help_page_path('administration/incoming_email', anchor: 'set-it-up'),
          svg_path: ActionController::Base.helpers.image_path('illustrations/service-desk-setup.svg')
        })
      }
    end
  end
end
