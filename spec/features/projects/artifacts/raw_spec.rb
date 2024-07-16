# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Raw artifact', feature_category: :job_artifacts do
  let(:project) { create(:project, :public) }
  let(:pipeline) { create(:ci_empty_pipeline, project: project) }
  let(:job) { create(:ci_build, :artifacts, pipeline: pipeline) }

  def raw_path(path)
    raw_project_job_artifacts_path(project, job, path)
  end

  context 'when visiting old URL' do
    let(:raw_url) do
      raw_path('other_artifacts_0.1.2/doc_sample.txt')
    end

    before do
      visit raw_url.sub('/-/jobs', '/builds')
    end

    it "redirects to new URL" do
      expect(page).to have_current_path(raw_url, ignore_query: true)
    end
  end
end
