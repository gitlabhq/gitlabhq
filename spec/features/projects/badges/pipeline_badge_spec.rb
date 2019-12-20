# frozen_string_literal: true

require 'spec_helper'

describe 'Pipeline Badge' do
  set(:project) { create(:project, :repository, :public) }
  let(:ref) { project.default_branch }

  context 'when the project has a pipeline' do
    let!(:pipeline) { create(:ci_empty_pipeline, project: project, ref: ref, sha: project.commit(ref).sha) }
    let!(:job) { create(:ci_build, pipeline: pipeline) }

    context 'when the pipeline was successful' do
      it 'displays so on the badge', :sidekiq_might_not_need_inline do
        job.success

        visit pipeline_project_badges_path(project, ref: ref, format: :svg)

        expect(page.status_code).to eq(200)
        expect_badge('passed')
      end
    end

    context 'when the pipeline failed' do
      it 'shows displays so on the badge', :sidekiq_might_not_need_inline do
        job.drop

        visit pipeline_project_badges_path(project, ref: ref, format: :svg)

        expect(page.status_code).to eq(200)
        expect_badge('failed')
      end
    end

    context 'when the pipeline is preparing' do
      let!(:job) { create(:ci_build, status: 'created', pipeline: pipeline) }

      before do
        # Prevent skipping directly to 'pending'
        allow(Ci::BuildPrepareWorker).to receive(:perform_async)
        allow(job).to receive(:prerequisites).and_return([double])
      end

      it 'displays the preparing badge', :sidekiq_might_not_need_inline do
        job.enqueue

        visit pipeline_project_badges_path(project, ref: ref, format: :svg)

        expect(page.status_code).to eq(200)
        expect_badge('preparing')
      end
    end

    context 'when the pipeline is running' do
      it 'shows displays so on the badge', :sidekiq_might_not_need_inline do
        create(:ci_build, pipeline: pipeline, name: 'second build', status_event: 'run')

        visit pipeline_project_badges_path(project, ref: ref, format: :svg)

        expect(page.status_code).to eq(200)
        expect_badge('running')
      end
    end

    context 'when a new pipeline is created' do
      it 'shows a fresh badge' do
        visit pipeline_project_badges_path(project, ref: ref, format: :svg)

        expect(page.status_code).to eq(200)
        expect(page.response_headers['Cache-Control']).to include 'no-cache'
      end
    end

    def expect_badge(status)
      svg = Nokogiri::XML.parse(page.body)
      expect(page.response_headers['Content-Type']).to include('image/svg+xml')
      expect(svg.at(%Q{text:contains("#{status}")})).to be_truthy
    end
  end
end
