# frozen_string_literal: true

require 'spec_helper'

describe 'Projects > Settings > For a forked project', :js do
  let(:user) { create(:user) }
  let(:project) { create(:project, :repository) }
  let(:role) { :maintainer }

  before do
    sign_in(user)
    project.add_role(user, role)
  end

  describe 'Sidebar > Operations' do
    it 'renders the settings link in the sidebar' do
      visit project_path(project)
      wait_for_requests

      expect(page).to have_selector('a[title="Operations"]', visible: false)
    end
  end
end
