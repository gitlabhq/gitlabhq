# frozen_string_literal: true

require "spec_helper"

RSpec.describe RapidDiffs::MergeRequestAppComponent, feature_category: :code_review_workflow do
  let(:app_component) { instance_double(RapidDiffs::AppComponent) }
  let(:diffs_stats_endpoint) { '/diffs_stats' }
  let(:diff_files_endpoint) { '/diff_files_metadata' }
  let(:diff_file_endpoint) { '/diff_file' }
  let(:mr_path) { '/group/project/-/merge_requests/1' }
  let(:merge_request) { build_stubbed(:merge_request) }
  let(:code_review_enabled) { false }
  let(:discussions_endpoint) { '/discussions' }
  let(:user_permissions) { { can_create_note: true } }
  let(:noteable_type) { 'MergeRequest' }
  let(:preview_markdown_endpoint) { '/preview_markdown' }
  let(:register_path) { '/register' }
  let(:sign_in_path) { '/sign_in' }
  let(:markdown_docs_path) { '/markdown_docs' }
  let(:report_abuse_path) { '/report_abuse' }

  let(:presenter) do
    instance_double(
      ::RapidDiffs::MergeRequestPresenter,
      diffs_stats_endpoint: diffs_stats_endpoint,
      diff_files_endpoint: diff_files_endpoint,
      diff_file_endpoint: diff_file_endpoint,
      discussions_endpoint: discussions_endpoint,
      user_permissions: user_permissions,
      noteable_type: noteable_type,
      preview_markdown_endpoint: preview_markdown_endpoint,
      register_path: register_path,
      sign_in_path: sign_in_path,
      markdown_docs_path: markdown_docs_path,
      report_abuse_path: report_abuse_path,
      code_review_enabled: code_review_enabled,
      environment: nil,
      resource: merge_request,
      mr_path: mr_path
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
    expect(RapidDiffs::AppComponent).to receive(:new).with(
      presenter,
      extra_app_data: {
        mr_path: mr_path,
        code_review_enabled: false,
        user_permissions: user_permissions,
        discussions_endpoint: discussions_endpoint,
        noteable_type: noteable_type,
        preview_markdown_endpoint: preview_markdown_endpoint,
        register_path: register_path,
        sign_in_path: sign_in_path,
        report_abuse_path: report_abuse_path,
        markdown_docs_path: markdown_docs_path
      }
    )

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

  describe 'viewed FOUC prevention' do
    let(:code_review_enabled) { true }

    it 'includes startup_js for FOUC prevention when code review is enabled' do
      render_component

      expect(component.helpers.content_for?(:startup_js)).to be(true)
    end

    context 'when code review is disabled' do
      let(:code_review_enabled) { false }

      it 'does not include startup_js for FOUC prevention' do
        render_component

        expect(component.helpers.content_for?(:startup_js)).to be(false)
      end
    end
  end

  def render_component
    render_inline(component)
  end
end
