# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Promotions', :js, feature_category: :service_desk do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project_empty_repo) }

  describe 'for service desk', :js do
    before do
      project.add_maintainer(user)
      sign_in(user)
    end

    context 'when service desk is not supported' do
      before do
        allow(::ServiceDesk).to receive(:supported?).and_return(false)
      end

      it 'appears in project edit page' do
        visit edit_project_path(project)

        expect(find('#promote_service_desk')).to have_content 'Improve customer support with Service Desk'
      end

      it 'does not show when cookie is set' do
        visit edit_project_path(project)

        within('#promote_service_desk') do
          find('.js-close').click
        end

        wait_for_requests

        visit edit_project_path(project)

        expect(page).not_to have_selector('#promote_service_desk')
      end
    end

    context 'when service desk is supported' do
      before do
        allow(::ServiceDesk).to receive(:supported?).and_return(true)
      end

      it 'does not show promotion' do
        visit edit_project_path(project)

        expect(page).not_to have_selector('#promote_service_desk')
      end
    end
  end
end
