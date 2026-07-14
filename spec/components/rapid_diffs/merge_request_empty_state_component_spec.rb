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

  describe ':no_changes' do
    let(:presenter) { instance_double(MergeRequestPresenter, can_push_to_source_branch?: can_push) }

    before do
      allow(merge_request).to receive(:present).and_return(presenter)
    end

    context 'when the user can push to the source branch' do
      let(:can_push) { true }

      it 'renders the no-changes copy and a Create commit button', :aggregate_failures do
        render_inline(described_class.new(merge_request: merge_request, type: :no_changes))

        expect(page).to have_text('There are no changes yet')
        expect(page).to have_text('No changes between feature and main')
        expect(page).to have_link('Create commit')
      end
    end

    context 'when the user cannot push to the source branch' do
      let(:can_push) { false }

      it 'does not render the Create commit button', :aggregate_failures do
        render_inline(described_class.new(merge_request: merge_request, type: :no_changes))

        expect(page).to have_text('There are no changes yet')
        expect(page).not_to have_link('Create commit')
      end
    end

    context 'when type is unknown' do
      let(:can_push) { false }

      it 'falls back to the no-changes empty state' do
        render_inline(described_class.new(merge_request: merge_request, type: :unknown_state))

        expect(page).to have_text('There are no changes yet')
      end
    end
  end
end
