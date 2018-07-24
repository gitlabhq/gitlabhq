require 'spec_helper'
require 'tempfile'

describe 'Jobs', :clean_gitlab_redis_shared_state do
  let(:user) { create(:user) }
  let(:user_access_level) { :developer }
  let(:pipeline) { create(:ci_pipeline, project: project) }

  let(:job) { create(:ci_build, :trace_live, pipeline: pipeline) }

  before do
    project.add_role(user, user_access_level)
    sign_in(user)
  end

  describe "GET /:project/jobs/:id" do
    context 'job project is over shared runners limit' do
      let(:group) { create(:group, :with_used_build_minutes_limit) }
      let(:project) { create(:project, :repository, namespace: group, shared_runners_enabled: true) }

      it 'displays a warning message' do
        visit project_job_path(project, job)

        expect(page).to have_content('You have used all your shared Runners pipeline minutes.')
      end
    end
  end
end
