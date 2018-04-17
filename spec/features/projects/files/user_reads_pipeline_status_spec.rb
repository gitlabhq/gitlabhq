require 'spec_helper'

describe 'user reads pipeline status', :js do
  let(:project) { create(:project, :repository) }
  let(:user) { create(:user) }
  let(:v110_pipeline) { create_pipeline('v1.1.0', 'success') }
  let(:x110_pipeline) { create_pipeline('x1.1.0', 'failed') }

  before do
    project.add_master(user)

    project.repository.add_tag(user, 'x1.1.0', 'v1.1.0')
    v110_pipeline
    x110_pipeline

    sign_in(user)
  end

  shared_examples 'visiting project tree' do
    scenario 'sees the correct pipeline status' do
      visit project_tree_path(project, expected_pipeline.ref)
      wait_for_requests

      page.within('.blob-commit-info') do
        expect(page).to have_link('', href: project_pipeline_path(project, expected_pipeline))
        expect(page).to have_selector(".ci-status-icon-#{expected_pipeline.status}")
      end
    end
  end

  it_behaves_like 'visiting project tree' do
    let(:expected_pipeline) { v110_pipeline }
  end

  it_behaves_like 'visiting project tree' do
    let(:expected_pipeline) { x110_pipeline }
  end

  def create_pipeline(ref, status)
    create(:ci_pipeline,
      project: project,
      ref: ref,
      sha: project.commit(ref).sha,
      status: status)
  end
end
