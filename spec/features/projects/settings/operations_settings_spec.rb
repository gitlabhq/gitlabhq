# frozen_string_literal: true

require 'spec_helper'

describe 'Projects > Settings > For a forked project', :js do
  let(:user) { create(:user) }
  let(:project) { create(:project, :repository) }
  let(:role) { :maintainer }

  before do
    stub_feature_flags(error_tracking: true)
    sign_in(user)
    project.add_role(user, role)
  end

  describe 'Sidebar > Operations' do
    context 'when sidebar feature flag enabled' do
      it 'renders the settings link in the sidebar' do
        visit project_path(project)
        wait_for_requests

        expect(page).to have_selector('a[title="Operations"]', visible: false)
      end
    end

    context 'when sidebar feature flag disabled' do
      before do
        stub_feature_flags(error_tracking: false)
      end

      it 'does not render the settings link in the sidebar' do
        visit project_path(project)
        wait_for_requests

        expect(page).not_to have_selector('a[title="Operations"]', visible: false)
      end
    end
  end
end
