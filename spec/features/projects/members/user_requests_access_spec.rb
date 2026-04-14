# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Projects > Members > User requests access', :js, feature_category: :groups_and_projects do
  include Spec::Support::Helpers::ModalHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:maintainer) { create(:user) }
  let_it_be(:project) { create(:project, :public, :repository, maintainers: [maintainer]) }

  let(:owner) { project.first_owner }
  let(:more_actions_dropdown) do
    find_by_testid('projects-list-item-actions')
  end

  context 'when user has no existing access request' do
    before do
      sign_in(user)
      visit project_path(project)
    end

    it 'request access feature is disabled' do
      project.update!(request_access_enabled: false)
      visit project_path(project)

      more_actions_dropdown.click
      expect(page).not_to have_content 'Request access'
    end

    it 'user can request access to a project',
      quarantine: {
        issue: 'https://gitlab.com/gitlab-org/quality/test-failure-issues/-/work_items/39483',
        type: 'flaky'
      } do
      perform_enqueued_jobs do
        more_actions_dropdown.click
        request_access
      end

      expect(ActionMailer::Base.deliveries.map(&:to)).to match_array([[owner.notification_email_or_default], [maintainer.notification_email_or_default]])
      expect(ActionMailer::Base.deliveries.last.subject).to eq "Request to join the #{project.full_name} project"

      expect(page).to have_content 'Your request for access has been queued for review.'

      more_actions_dropdown.click
      expect(page).to have_content 'Withdraw access request'
      expect(page).not_to have_content 'Leave project'
    end

    context 'code access is restricted' do
      it 'user can request access' do
        project.project_feature.update!(
          repository_access_level: ProjectFeature::PRIVATE,
          builds_access_level: ProjectFeature::PRIVATE,
          merge_requests_access_level: ProjectFeature::PRIVATE
        )
        visit project_path(project)
        more_actions_dropdown.click

        expect(page).to have_content 'Request access'
      end
    end
  end

  context 'when user has request for access' do
    let!(:access_request) { create(:project_member, :access_request, project: project, user: user) }

    before do
      sign_in(user)
      visit project_path(project)
    end

    it 'user is not listed in the project members page' do
      within_testid('super-sidebar') do
        click_button 'Manage'
        click_link 'Members'
      end

      page.within('.content') do
        expect(page).not_to have_content(user.name)
      end
    end

    it 'user can withdraw request' do
      more_actions_dropdown.click
      withdraw_access

      expect(page).to have_content 'Your access request to the project has been withdrawn.'
    end
  end

  def request_access
    find_by_testid('request-access-link').click
    wait_for_requests
  end

  def withdraw_access
    find_by_testid('withdraw-access-link').click
    accept_gl_confirm
    wait_for_requests
  end
end
