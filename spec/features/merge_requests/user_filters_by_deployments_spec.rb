# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Merge Requests > User filters by deployments', :js, feature_category: :code_review_workflow do
  include FilteredSearchHelpers

  let!(:project) { create(:project, :public, :repository) }
  let!(:user) { project.creator }
  let!(:gstg) { create(:environment, project: project, name: 'gstg') }
  let!(:gprd) { create(:environment, project: project, name: 'gprd') }

  let(:mr1) do
    create(
      :merge_request,
      :simple,
      :merged,
      author: user,
      source_project: project,
      target_project: project
    )
  end

  let(:mr2) do
    create(
      :merge_request,
      :simple,
      :merged,
      author: user,
      source_project: project,
      target_project: project
    )
  end

  let(:deploy1) do
    create(
      :deployment,
      :success,
      deployable: nil,
      environment: gstg,
      project: project,
      sha: mr1.diff_head_sha,
      finished_at: Time.utc(2020, 10, 1, 0, 0)
    )
  end

  let(:deploy2) do
    create(
      :deployment,
      :success,
      deployable: nil,
      environment: gprd,
      project: project,
      sha: mr2.diff_head_sha,
      finished_at: Time.utc(2020, 10, 2, 0, 0)
    )
  end

  before do
    deploy1.link_merge_requests(MergeRequest.where(id: mr1.id))
    deploy2.link_merge_requests(MergeRequest.where(id: mr2.id))

    sign_in(user)
    visit(project_merge_requests_path(project, state: :merged))
  end

  describe 'filtering by deployed-before' do
    it 'applies the filter' do
      select_tokens 'Deployed-before'
      find_by_testid('filtered-search-token-segment-input').send_keys '2020-10-02'

      send_keys :enter

      expect(page).to have_issuable_counts(open: 0, merged: 1, all: 1)
      expect(page).to have_content mr1.title
    end
  end

  describe 'filtering by deployed-after' do
    it 'applies the filter' do
      select_tokens 'Deployed-after'
      find_by_testid('filtered-search-token-segment-input').send_keys '2020-10-01'

      send_keys :enter

      expect(page).to have_issuable_counts(open: 0, merged: 1, all: 1)
      expect(page).to have_content mr2.title
    end
  end

  describe 'filtering by environment' do
    it 'applies the filter' do
      select_tokens 'Environment', 'gstg', submit: true

      expect(page).to have_issuable_counts(open: 0, merged: 1, all: 1)
      expect(page).to have_content mr1.title
    end
  end
end
