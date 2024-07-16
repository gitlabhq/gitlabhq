# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Upload ci artifact', :api, :js, feature_category: :job_artifacts do
  include_context 'file upload requests helpers'

  let_it_be(:user) { create(:user, :admin) }
  let_it_be(:project) { create(:project) }
  let_it_be(:pipeline) { create(:ci_pipeline, project: project, ref: 'master') }
  let_it_be(:runner) { create(:ci_runner, :project, projects: [project]) }
  let_it_be(:job) { create(:ci_build, :running, user: user, project: project, pipeline: pipeline, runner_id: runner.id) }

  let(:api_path) { "/jobs/#{job.id}/artifacts?token=#{job.token}" }
  let(:url) { capybara_url(api(api_path)) }
  let(:file) { fixture_file_upload('spec/fixtures/ci_build_artifacts.zip') }

  subject do
    HTTParty.post(url, body: { file: file })
  end

  RSpec.shared_examples 'for ci artifact' do
    it { expect { subject }.to change { ::Ci::JobArtifact.count }.by(2) }

    it { expect(subject.code).to eq(201) }
  end

  it_behaves_like 'handling file uploads', 'for ci artifact'
end
