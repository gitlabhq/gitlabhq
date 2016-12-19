require 'spec_helper'

feature 'CI shared runner limits', feature: true do
  let(:user) { create(:user) }

  before do
    login_as(user)
  end

  context 'with project' do
    let(:project) { create(:project, namespace: namespace, shared_runners_enabled: true) }
    let(:namespace) { create(:namespace) }

    before do
      project.team << [user, :developer]
    end

    context 'without limit' do
      scenario 'it does not display a warning message on project homepage' do
        visit namespace_project_path(project.namespace, project)
        expect_no_quota_exceeded_alert
      end
    end

    context 'when limit is defined' do
      context 'when limit is exceeded' do
        let(:namespace) { create(:namespace, :with_used_build_minutes_limit) }

        scenario 'it displays a warning message on project homepage' do
          visit namespace_project_path(project.namespace, project)
          expect_quota_exceeded_alert('You have exceeded your build minutes quota.')
        end
      end

      context 'when limit not yet exceeded' do
        let(:namespace) { create(:namespace, :with_not_used_build_minutes_limit) }

        scenario 'it does not display a warning message on project homepage' do
          visit namespace_project_path(project.namespace, project)
          expect_no_quota_exceeded_alert
        end
      end

      context 'when minutes are not yet set' do
        let(:namespace) { create(:namespace, :with_build_minutes_limit) }

        scenario 'it does not display a warning message on project homepage' do
          visit namespace_project_path(project.namespace, project)
          expect_no_quota_exceeded_alert
        end
      end
    end
  end

  def expect_quota_exceeded_alert(message = nil)
    expect(page).to have_selector('.shared-runner-quota-message', count: 1)
    expect(page.find('.shared-runner-quota-message')).to have_content(message) unless message.nil?
  end

  def expect_no_quota_exceeded_alert
    expect(page).not_to have_selector('.shared-runner-quota-message')
  end
end
