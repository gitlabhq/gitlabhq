# frozen_string_literal: true

module QA
  RSpec.describe 'Release', :runner do
    # TODO: Convert back to :smoke once proved to be stable. Related issue: https://gitlab.com/gitlab-org/gitlab/-/issues/300906
    describe 'Pages' do
      let!(:project) do
        Resource::Project.fabricate_via_api! do |project|
          project.name = 'jekyll-pages-project'
          project.template_name = :jekyll
        end
      end

      let(:pipeline) do
        Resource::Pipeline.fabricate_via_api! do |pipeline|
          pipeline.project = project
          pipeline.variables =
            { key: :CI_PAGES_DOMAIN, value: 'nip.io', variable_type: :env_var },
            { key: :CI_PAGES_URL, value: 'http://127.0.0.1.nip.io', variable_type: :env_var }
        end
      end

      before do
        Flow::Login.sign_in

        Resource::Runner.fabricate_via_api! do |runner|
          runner.project = project
          runner.executor = :docker
        end

        pipeline.visit!
      end

      it 'runs a Pages-specific pipeline', testcase: 'https://gitlab.com/gitlab-org/quality/testcases/-/issues/1783' do
        Page::Project::Pipeline::Show.perform do |show|
          expect(show).to have_job(:pages)
          show.click_job(:pages)
        end

        Page::Project::Job::Show.perform do |show|
          expect(show).to have_passed(timeout: 300)
        end
      end
    end
  end
end
