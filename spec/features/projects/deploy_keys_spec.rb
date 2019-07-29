# frozen_string_literal: true

require 'spec_helper'

describe 'Project deploy keys', :js do
  let(:user) { create(:user) }
  let(:project) { create(:project_empty_repo) }

  before do
    project.add_maintainer(user)
    sign_in(user)
  end

  describe 'removing key' do
    before do
      create(:deploy_keys_project, project: project)
    end

    it 'removes association between project and deploy key' do
      visit project_settings_repository_path(project)

      page.within(find('.deploy-keys')) do
        expect(page).to have_selector('.deploy-key', count: 1)

        accept_confirm { find('.ic-remove').click }

        wait_for_requests

        expect(page).to have_selector('.deploy-key', count: 0)
      end
    end
  end
end
