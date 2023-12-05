# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'user reads pipeline status', :js, feature_category: :continuous_integration do
  let(:project) { create(:project, :repository) }
  let(:user) { create(:user) }
  let(:v110_pipeline) { create_pipeline('v1.1.0', 'success') }
  let(:x110_pipeline) { create_pipeline('x1.1.0', 'failed') }

  before do
    project.add_maintainer(user)

    project.repository.add_tag(user, 'x1.1.0', 'v1.1.0')
    v110_pipeline
    x110_pipeline

    sign_in(user)
  end

  shared_examples 'visiting project tree' do
    it 'sees the correct pipeline status' do
      visit project_tree_path(project, expected_pipeline.ref)
      wait_for_requests

      page.within('.commit-detail') do
        expect(page).to have_link('', href: project_pipeline_path(project, expected_pipeline))
        expect(page).to have_selector("[data-testid='status_#{expected_pipeline.status}_borderless-icon']")
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
