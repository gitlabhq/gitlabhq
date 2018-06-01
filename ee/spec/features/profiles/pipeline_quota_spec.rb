require 'spec_helper'

describe 'Profile > Pipeline Quota' do
  using RSpec::Parameterized::TableSyntax

  set(:user) { create(:user) }
  set(:namespace) { user.namespace }
  set(:statistics) { create(:namespace_statistics, namespace: namespace) }
  set(:project) { create(:project, namespace: namespace) }
  set(:other_project) { create(:project, namespace: namespace, shared_runners_enabled: false) }

  before do
    gitlab_sign_in(user)
  end

  it 'is linked within the profile page' do
    visit profile_path

    page.within('.nav-sidebar') do
      expect(page).to have_selector(:link_or_button, 'Pipeline quota')
    end
  end

  describe 'shared runners use' do
    where(:shared_runners_enabled, :used, :quota, :usage_class, :usage_text) do
      false | 300  | 500 | 'success' | '300 / Unlimited minutes Unlimited'
      true  | 300  | nil | 'success' | '300 / Unlimited minutes Unlimited'
      true  | 300  | 500 | 'success' | '300 / 500 minutes 60% used'
      true  | 1000 | 500 | 'danger'  | '1000 / 500 minutes 200% used'
    end

    with_them do
      let(:no_shared_runners_text) { 'This group has no projects which use shared runners' }

      before do
        project.update!(shared_runners_enabled: shared_runners_enabled)
        statistics.update!(shared_runners_seconds: used.minutes.to_i)
        namespace.update!(shared_runners_minutes_limit: quota)

        visit profile_pipeline_quota_path
      end

      it 'shows the correct quota status' do
        page.within('.pipeline-quota') do
          expect(page).to have_content(usage_text)
          expect(page).to have_selector(".bg-#{usage_class}")
        end
      end

      it 'shows the correct per-project metrics' do
        page.within('.pipeline-project-metrics') do
          expect(page).not_to have_content(other_project.name)

          if shared_runners_enabled
            expect(page).to have_content(project.name)
            expect(page).not_to have_content(no_shared_runners_text)
          else
            expect(page).not_to have_content(project.name)
            expect(page).to have_content(no_shared_runners_text)
          end
        end
      end
    end
  end
end
