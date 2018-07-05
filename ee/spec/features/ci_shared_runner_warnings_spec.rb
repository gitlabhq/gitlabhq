require 'spec_helper'

describe 'CI shared runner limits' do
  let(:user) { create(:user) }
  let!(:project) { create(:project, :repository, namespace: group, shared_runners_enabled: true) }
  let(:group) { create(:group) }

  before do
    sign_in(user)
  end

  context 'when project member' do
    before do
      group.add_developer(user)
    end

    context 'without limit' do
      it 'it does not display a warning message on project homepage' do
        visit_project_home
        expect_no_quota_exceeded_alert
      end

      it 'it does not display a warning message on pipelines page' do
        visit_project_pipelines
        expect_no_quota_exceeded_alert
      end
    end

    context 'when limit is defined' do
      context 'when limit is exceeded' do
        let(:group) { create(:group, :with_used_build_minutes_limit) }

        it 'it displays a warning message on project homepage' do
          visit_project_home
          expect_quota_exceeded_alert("#{group.name} has exceeded their pipeline minutes quota.")
        end

        it 'it displays a warning message on pipelines page' do
          visit_project_pipelines
          expect_quota_exceeded_alert("#{group.name} has exceeded their pipeline minutes quota.")
        end
      end

      context 'when limit not yet exceeded' do
        let(:group) { create(:group, :with_not_used_build_minutes_limit) }

        it 'it does not display a warning message on project homepage' do
          visit_project_home
          expect_no_quota_exceeded_alert
        end

        it 'it does not display a warning message on pipelines page' do
          visit_project_pipelines
          expect_no_quota_exceeded_alert
        end
      end

      context 'when minutes are not yet set' do
        let(:group) { create(:group, :with_build_minutes_limit) }

        it 'it does not display a warning message on project homepage' do
          visit_project_home
          expect_no_quota_exceeded_alert
        end

        it 'it does not display a warning message on pipelines page' do
          visit_project_pipelines
          expect_no_quota_exceeded_alert
        end
      end
    end
  end

  context 'when not a project member' do
    let(:group) { create(:group, :with_used_build_minutes_limit) }

    context 'when limit is defined and limit is exceeded' do
      it 'it does not display a warning message on project homepage' do
        visit_project_home
        expect_no_quota_exceeded_alert
      end

      it 'it does not display a warning message on pipelines page' do
        visit_project_pipelines
        expect_no_quota_exceeded_alert
      end
    end
  end

  def visit_project_home
    visit project_path(project)
  end

  def visit_project_pipelines
    visit project_pipelines_path(project)
  end

  def expect_quota_exceeded_alert(message = nil)
    expect(page).to have_selector('.shared-runner-quota-message', count: 1)
    expect(page.find('.shared-runner-quota-message')).to have_content(message) unless message.nil?
  end

  def expect_no_quota_exceeded_alert
    expect(page).not_to have_selector('.shared-runner-quota-message')
  end
end
