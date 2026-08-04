# frozen_string_literal: true

module QA
  RSpec.describe 'Verify', feature_category: :continuous_integration,
    feature_flag: { name: 'vue3_migrate_jobs' } do
    # Verifies the Vue 3 rollout mechanism end-to-end on the environment
    # under test, including packaged builds (Omnibus/CNG): Rails resolves
    # the page entrypoint from the compiled `vue3_migration.json` manifest
    # and serves the Vue 3 bundle when the rollout feature flag is enabled.
    #
    # The Vue 3 runtime tags every mounted app root with a
    # `data-gitlab-vue3-app="<app name>"` attribute (see
    # `app/assets/javascripts/lib/utils/vue3compat/vue.js`), which is the
    # official hook for asserting that a page really mounted under Vue 3.
    # Without it, a broken rollout is invisible: pages fall back to Vue 2
    # and render normally.
    describe 'Vue 3 rollout', :requires_admin do
      let(:project) { create(:project, name: 'vue3-rollout-jobs') }

      # Always rendered by the jobs list app, under Vue 2 and Vue 3 alike.
      # Used to know the app mounted before asserting the marker.
      let(:jobs_app_anchor) { '[data-testid="jobs-all-tab"]' }

      # Root Vue app of the jobs list page, see `initJobsPage` in
      # `app/assets/javascripts/ci/jobs_page/index.js`.
      let(:vue3_marker) { '[data-gitlab-vue3-app="JobsTableAppRoot"]' }

      before do
        Flow::Login.sign_in
      end

      after do
        Runtime::Feature.disable(:vue3_migrate_jobs)
      end

      it 'serves the jobs page with Vue 2 by default and Vue 3 when the rollout flag is enabled',
        testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/606899',
        quarantine: {
          issue: 'https://gitlab.com/gitlab-org/quality/test-failure-issues/-/issues/43839',
          type: :flaky
        } do
        project.visit!
        Page::Project::Menu.perform(&:go_to_jobs)

        expect(page).to have_css(jobs_app_anchor)
        expect(page).to have_no_css(vue3_marker)

        Runtime::Feature.enable(:vue3_migrate_jobs)
        page.refresh

        expect(page).to have_css(jobs_app_anchor)
        expect(page).to have_css(vue3_marker)
      end
    end
  end
end
