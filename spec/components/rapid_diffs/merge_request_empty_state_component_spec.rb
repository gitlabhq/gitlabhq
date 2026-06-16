# frozen_string_literal: true

require "spec_helper"

RSpec.describe RapidDiffs::MergeRequestEmptyStateComponent, feature_category: :code_review_workflow do
  let(:merge_request) { build_stubbed(:merge_request, source_branch: 'feature', target_branch: 'main') }

  it 'renders the building message for :initial_preparation' do
    render_inline(described_class.new(merge_request: merge_request, type: :initial_preparation))

    expect(page).to have_text('Building your merge request')
  end

  it 'renders the already-merged message and branch names for :already_merged', :aggregate_failures do
    render_inline(described_class.new(merge_request: merge_request, type: :already_merged))

    expect(page).to have_text('Changes already merged')
    expect(page).to have_text('All changes from feature are already present in main.')
  end

  it 'falls back to the default empty state for :no_changes' do
    render_inline(described_class.new(merge_request: merge_request, type: :no_changes))

    expect(page).to have_text('There are no changes')
  end

  it 'falls back to the default empty state when type is unknown' do
    render_inline(described_class.new(merge_request: merge_request, type: :unknown_state))

    expect(page).to have_text('There are no changes')
  end
end
