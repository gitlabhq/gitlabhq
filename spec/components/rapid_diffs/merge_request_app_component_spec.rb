# frozen_string_literal: true

require "spec_helper"

RSpec.describe RapidDiffs::MergeRequestAppComponent, feature_category: :code_review_workflow do
  let(:app_component) { instance_double(RapidDiffs::AppComponent) }
  let(:diffs_stats_endpoint) { '/diffs_stats' }
  let(:diff_files_endpoint) { '/diff_files_metadata' }
  let(:diff_file_endpoint) { '/diff_file' }
  let(:mr_path) { '/group/project/-/merge_requests/1' }
  let(:project_path) { 'group/project' }
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
  let(:versions) { { 'source_versions' => [], 'target_versions' => [] } }
  let(:suggestions_help_path) { '/help/suggestions' }
  let(:default_suggestion_commit_message) { 'Apply suggestion' }
  let(:new_comment_template_paths) do
    [{
      text: 'Your comment templates',
      href: ::Gitlab::Routing.url_helpers.profile_comment_templates_path
    }]
  end

  let(:presenter) do
    double( # rubocop:disable RSpec/VerifiedDoubles -- preparing? is delegated via SimpleDelegator at runtime
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
      mr_path: mr_path,
      project_path: project_path,
      versions: versions,
      suggestions_help_path: suggestions_help_path,
      default_suggestion_commit_message: default_suggestion_commit_message,
      new_comment_template_paths: new_comment_template_paths,
      linked_file: nil,
      preparing?: false
    )
  end

  subject(:component) { described_class.new(presenter) }

  before do
    allow(RapidDiffs::AppComponent).to receive(:new).and_return(app_component)
    allow(app_component).to receive(:render_in).and_yield(app_component)
    allow(app_component).to receive(:with_before_diffs_list).and_yield
    allow(app_component).to receive(:with_diffs_list).and_yield
    allow(app_component).to receive_messages(diff_collection: [], parallel_view?: false)
  end

  it "renders app with correct arguments" do
    expect(RapidDiffs::AppComponent).to receive(:new).with(
      presenter,
      extra_app_data: {
        mr_path: mr_path,
        project_path: project_path,
        code_review_enabled: false,
        user_permissions: user_permissions,
        discussions_endpoint: discussions_endpoint,
        noteable_type: noteable_type,
        preview_markdown_endpoint: preview_markdown_endpoint,
        register_path: register_path,
        sign_in_path: sign_in_path,
        report_abuse_path: report_abuse_path,
        markdown_docs_path: markdown_docs_path,
        suggestions_help_path: suggestions_help_path,
        default_suggestion_commit_message: default_suggestion_commit_message,
        new_comment_template_paths: new_comment_template_paths,
        versions: versions
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

      startup_js = component.helpers.content_for(:startup_js)
      expect(startup_js).to be_present
      expect(startup_js).to include('const linkedFileCodeReviewId = null')
    end

    context 'when code review is disabled' do
      let(:code_review_enabled) { false }

      it 'does not include startup_js for FOUC prevention' do
        render_component

        expect(component.helpers.content_for?(:startup_js)).to be(false)
      end
    end

    context 'when viewing a linked file' do
      let(:linked_file) { instance_double(Gitlab::Diff::File, code_review_id: 'linked-file-id') }

      before do
        allow(presenter).to receive(:linked_file).and_return(linked_file)
      end

      it 'excludes the linked file from FOUC prevention' do
        render_component

        startup_js = component.helpers.content_for(:startup_js)
        expect(startup_js).to include('linked-file-id')
      end
    end
  end

  context 'when merge request is preparing' do
    before do
      allow(presenter).to receive(:preparing?).and_return(true)
      allow(app_component).to receive(:with_empty_state).and_yield
    end

    it 'renders building message' do
      render_component

      expect(page).to have_text('Building your merge request')
    end
  end

  it 'does not render building message when not preparing' do
    render_component

    expect(page).not_to have_text('Building your merge request')
  end

  context "when user has permission to create notes" do
    let(:user_permissions) { { can_create_note: true } }

    it "renders before_diffs_list slot with new discussion toggle" do
      render_component

      expect(page).to have_selector('[data-new-discussion-toggle][data-click="newDiscussion"][hidden]', visible: :all)
    end
  end

  context "when user does not have permission to create notes" do
    let(:user_permissions) { { can_create_note: false } }

    it "does not render new discussion toggle" do
      render_component

      expect(page).not_to have_selector('[data-new-discussion-toggle]', visible: :all)
    end
  end

  it "always renders commit widget placeholder" do
    render_component

    expect(page).to have_selector('[data-commit-widget]', visible: :all)
  end

  def render_component
    render_inline(component)
  end
end
