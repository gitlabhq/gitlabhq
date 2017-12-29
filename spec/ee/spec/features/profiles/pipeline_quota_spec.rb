require 'spec_helper'

feature 'Profile > Pipeline Quota' do
  before do
    # This would make sure that the user won't try to create another namespace
    allow_any_instance_of(User).to receive(:ensure_namespace_correct)
    gitlab_sign_in(user)
  end

  let(:user) { create(:user) }
  let(:namespace) { create(:namespace, owner: user) }
  let!(:project) { create(:project, namespace: namespace, shared_runners_enabled: true) }

  it 'is linked within the profile page' do
    visit profile_path

    page.within('.nav-sidebar') do
      expect(page).to have_selector(:link_or_button, 'Pipeline quota')
    end
  end

  context 'with no quota' do
    let(:namespace) { create(:namespace, :with_build_minutes, owner: user) }

    it 'shows correct group quota info' do
      visit profile_pipeline_quota_path

      page.within('.pipeline-quota') do
        expect(page).to have_content("400 / Unlimited minutes")
        expect(page).to have_selector('.progress-bar-success')
      end
    end
  end

  context 'with no projects using shared runners' do
    let(:namespace) { create(:namespace, :with_not_used_build_minutes_limit, owner: user) }
    let!(:project) { create(:project, namespace: namespace, shared_runners_enabled: false) }

    it 'shows correct group quota info' do
      visit profile_pipeline_quota_path

      page.within('.pipeline-quota') do
        expect(page).to have_content("300 / Unlimited minutes")
        expect(page).to have_selector('.progress-bar-success')
      end

      page.within('.pipeline-project-metrics') do
        expect(page).to have_content('This group has no projects which use shared runners')
      end
    end
  end

  context 'minutes under quota' do
    let(:namespace) { create(:namespace, :with_not_used_build_minutes_limit, owner: user) }

    it 'shows correct group quota info' do
      visit profile_pipeline_quota_path

      page.within('.pipeline-quota') do
        expect(page).to have_content("300 / 500 minutes")
        expect(page).to have_content("60% used")
        expect(page).to have_selector('.progress-bar-success')
      end
    end
  end

  context 'minutes over quota' do
    let(:namespace) { create(:namespace, :with_used_build_minutes_limit, owner: user) }
    let!(:other_project) { create(:project, namespace: namespace, shared_runners_enabled: false) }

    it 'shows correct group quota and projects info' do
      visit profile_pipeline_quota_path

      page.within('.pipeline-quota') do
        expect(page).to have_content("1000 / 500 minutes")
        expect(page).to have_content("200% used")
        expect(page).to have_selector('.progress-bar-danger')
      end

      page.within('.pipeline-project-metrics') do
        expect(page).to have_content(project.name)
        expect(page).not_to have_content(other_project.name)
      end
    end
  end
end
