# frozen_string_literal: true

module QA
  RSpec.describe 'Plan',
    :gitlab_pages,
    :orchestrated,
    quarantine: {
      issue: 'https://gitlab.com/gitlab-org/gitlab/-/issues/383215',
      type: :broken
    } do
    # TODO: Convert back to :smoke once proved to be stable. Related issue: https://gitlab.com/gitlab-org/gitlab/-/issues/300906
    describe 'Pages', product_group: :knowledge do
      let!(:project) { create(:project, name: 'gitlab-pages-projects', template_name: :plainhtml) }
      let(:pipeline) do
        create(:pipeline,
          project: project,
          variables: [
            { key: :CI_PAGES_DOMAIN, value: 'nip.io', variable_type: :env_var },
            { key: :CI_PAGES_URL, value: 'http://127.0.0.1.nip.io', variable_type: :env_var }
          ])
      end

      before do
        Flow::Login.sign_in
        create(:project_runner, project: project, executor: :docker)
        pipeline.visit!
      end

      it 'creates a Pages website',
        testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347669' do
        Page::Project::Pipeline::Show.perform do |show|
          expect(show).to have_job(:pages)
          show.click_job(:pages)
        end

        Page::Project::Job::Show.perform do |show|
          expect(show).to have_passed(timeout: 300)
        end

        Page::Project::Menu.perform(&:go_to_pages_settings)
        Page::Project::Pages.perform(&:go_to_access_page)

        Support::Waiter.wait_until(
          sleep_interval: 2,
          max_duration: 60,
          reload_page: page,
          retry_on_exception: true
        ) do
          expect(page).to have_content(
            'This is a simple plain-HTML website on GitLab Pages, without any fancy static site generator.'
          )
        end
      end
    end
  end
end
