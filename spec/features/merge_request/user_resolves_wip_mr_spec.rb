# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Merge request > User resolves Draft', :js, feature_category: :code_review_workflow do
  let(:project) { create(:project, :public, :repository) }
  let(:user) { project.creator }
  let(:merge_request) do
    create(
      :merge_request_with_diffs,
      source_project: project,
      author: user,
      title: 'Draft: Bug NS-04',
      merge_params: { force_remove_source_branch: '1' }
    )
  end

  let(:pipeline) do
    create(
      :ci_pipeline,
      project: project,
      sha: merge_request.diff_head_sha,
      ref: merge_request.source_branch,
      head_pipeline_of: merge_request
    )
  end

  before do
    project.add_maintainer(user)
  end

  context 'when there is active pipeline for merge request' do
    let(:feature_flags_state) { true }

    before do
      stub_feature_flags(merge_when_checks_pass: feature_flags_state, merge_blocked_component: feature_flags_state)

      create(:ci_build, pipeline: pipeline)

      sign_in(user)
      visit project_merge_request_path(project, merge_request)
      wait_for_requests
    end

    it 'retains merge request data after clicking Resolve WIP status' do
      # rubocop:disable RSpec/AvoidConditionalStatements -- remove when Auto merge goes to Foss
      # https://gitlab.com/gitlab-org/gitlab/-/merge_requests/146730
      expected_message = if Gitlab.ee?
                           "Set to auto-merge"
                         else
                           "Merge blocked:"
                         end
      # rubocop:enable RSpec/AvoidConditionalStatements

      expect(page.find('.ci-widget-content')).to have_content("Pipeline ##{pipeline.id}")
      expect(page).to have_content expected_message

      page.within('.mr-state-widget') do
        click_button('Mark as ready')
      end

      wait_for_requests

      # If we don't disable the wait here, the test will wait until the
      # merge request widget refreshes, which masks missing elements
      # that should already be present.
      expect(page.find('.ci-widget-content', wait: 0)).to have_content("Pipeline ##{pipeline.id}")
      expect(page).to have_content("Set to auto-merge")
    end

    context 'when the new merge_when_checks_pass and merge blocked components are disabled' do
      let(:feature_flags_state) { false }

      it 'retains merge request data after clicking Resolve WIP status' do
        expect(page.find('.ci-widget-content')).to have_content("Pipeline ##{pipeline.id}")
        expect(page).to have_content "Merge blocked: Select Mark as ready to remove it from Draft status."

        page.within('.mr-state-widget') do
          click_button('Mark as ready')
        end

        wait_for_requests

        # If we don't disable the wait here, the test will wait until the
        # merge request widget refreshes, which masks missing elements
        # that should already be present.
        expect(page.find('.ci-widget-content', wait: 0)).to have_content("Pipeline ##{pipeline.id}")
        expect(page).not_to have_content("Merge blocked")
      end
    end
  end
end
