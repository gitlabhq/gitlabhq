# frozen_string_literal: true

require "spec_helper"

RSpec.describe RapidDiffs::MergeRequestAppComponent, feature_category: :code_review_workflow do
  let(:app_component) { instance_double(RapidDiffs::AppComponent) }
  let(:diffs_stats_endpoint) { '/diffs_stats' }
  let(:diff_files_endpoint) { '/diff_files_metadata' }
  let(:diff_file_endpoint) { '/diff_file' }

  let(:merge_request) { build_stubbed(:merge_request) }

  let(:presenter) do
    instance_double(
      ::RapidDiffs::MergeRequestPresenter,
      diffs_stats_endpoint: diffs_stats_endpoint,
      diff_files_endpoint: diff_files_endpoint,
      diff_file_endpoint: diff_file_endpoint,
      environment: nil,
      resource: merge_request
    )
  end

  subject(:component) { described_class.new(presenter) }

  before do
    allow(RapidDiffs::AppComponent).to receive(:new).and_return(app_component)
    allow(app_component).to receive(:render_in).and_yield(app_component)
    allow(app_component).to receive(:with_diffs_list).and_yield
    allow(app_component).to receive_messages(diff_collection: [], parallel_view?: false)
  end

  it "renders app with correct arguments" do
    expect(RapidDiffs::AppComponent).to receive(:new).with(presenter)

    render_component
  end

  it "renders diffs_list slot with merge request diff files" do
    allow(RapidDiffs::MergeRequestDiffFileComponent).to receive(:with_collection).and_return([])

    render_component

    expect(RapidDiffs::MergeRequestDiffFileComponent).to have_received(:with_collection)
  end

  it "loads merge request rapid diffs stylesheet" do
    style_added = false
    allow(component).to receive(:helpers).and_wrap_original do |original_method, *args|
      helpers = original_method.call(*args)
      allow(helpers).to receive(:add_page_specific_style).with('page_bundles/merge_request_rapid_diffs') do
        style_added = true
      end
      helpers
    end

    render_component

    expect(style_added).to be(true)
  end

  def render_component
    render_inline(component)
  end
end
