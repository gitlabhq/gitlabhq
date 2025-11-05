# frozen_string_literal: true

require "spec_helper"

RSpec.describe RapidDiffs::AppComponent, type: :component, feature_category: :code_review_workflow do
  let_it_be(:diffs_slice) { Array.new(2, build(:diff_file)) }
  let(:diffs_stream_url) { '/stream' }
  let(:reload_stream_url) { '/reload_stream' }
  let(:show_whitespace) { true }
  let(:diff_view) { :inline }
  let(:update_user_endpoint) { '/update_user' }
  let(:diffs_stats_endpoint) { '/diffs_stats' }
  let(:diff_files_endpoint) { '/diff_files_metadata' }
  let(:diff_file_endpoint) { '/diff_file' }
  let(:should_sort_metadata_files) { false }
  let(:lazy) { false }

  let(:diff_presenter) do
    instance_double(
      ::RapidDiffs::BasePresenter,
      diffs_slice: diffs_slice,
      diffs_stream_url: diffs_stream_url,
      reload_stream_url: reload_stream_url,
      diffs_stats_endpoint: diffs_stats_endpoint,
      diff_files_endpoint: diff_files_endpoint,
      diff_file_endpoint: diff_file_endpoint,
      should_sort_metadata_files?: should_sort_metadata_files,
      lazy?: lazy
    )
  end

  subject(:component) { described_class.new(diff_presenter) }

  before do
    allow(component).to receive(:helpers).and_wrap_original do |original_method, *args|
      helpers = original_method.call(*args)
      allow(helpers).to receive_messages(
        hide_whitespace?: !show_whitespace,
        diff_view: diff_view,
        api_v4_user_preferences_path: update_user_endpoint
      )
      helpers
    end
  end

  it "renders app" do
    render_component
    expect(page).to have_css('[data-rapid-diffs]')
  end

  it "renders diffs slice" do
    render_component
    expect(page.all('diff-file').size).to eq(2)
  end

  it "renders app data" do
    render_component
    app = page.find('[data-rapid-diffs]')
    data = Gitlab::Json.parse(app['data-app-data'])
    expect(data['diffs_stream_url']).to eq(diffs_stream_url)
    expect(data['reload_stream_url']).to eq(reload_stream_url)
    expect(data['diffs_stats_endpoint']).to eq(diffs_stats_endpoint)
    expect(data['diff_files_endpoint']).to eq(diff_files_endpoint)
    expect(data['diff_file_endpoint']).to eq(diff_file_endpoint)
    expect(data['update_user_endpoint']).to eq(update_user_endpoint)
    expect(data['show_whitespace']).to eq(show_whitespace)
    expect(data['diff_view_type']).to eq(diff_view.to_s)
    expect(data['lazy']).to eq(lazy)
  end

  context "with should_sort_metadata_files set to true" do
    let(:should_sort_metadata_files) { true }

    it "enables sorting metadata" do
      render_component
      app = page.find('[data-rapid-diffs]')
      expect(Gitlab::Json.parse(app['data-app-data'])['should_sort_metadata_files']).to eq(should_sort_metadata_files)
    end
  end

  it "renders view settings" do
    render_component
    expect(page).to have_css('[data-view-settings]')
  end

  it "renders file browser toggle" do
    render_component
    container = page.find("[data-file-browser-toggle]")
    expect(container).not_to be_nil
  end

  it "renders sidebar" do
    render_component
    container = page.find("[data-file-browser]")
    expect(container).not_to be_nil
    expect(page).to have_css('[data-testid="rd-file-browser-loading"]')
  end

  it "sets sidebar width" do
    allow(vc_test_controller).to receive(:cookies).and_return({ mr_tree_list_width: '250' })
    render_component
    container = page.find("[data-file-browser]")
    expect(container[:style]).to include("width: 250px")
  end

  it "ignores invalid sidebar width" do
    allow(vc_test_controller).to receive(:cookies).and_return({ mr_tree_list_width: 'foobar' })
    render_component
    container = page.find("[data-file-browser]")
    expect(container[:style]).to be_empty
  end

  it "hides sidebar" do
    allow(vc_test_controller).to receive(:cookies).and_return({ file_browser_visible: 'false' })
    render_component
    expect(page).to have_css('[data-file-browser]', visible: :hidden)
  end

  it "renders stream container" do
    render_component
    expect(page).to have_css("[data-stream-remaining-diffs]")
  end

  it "renders diffs_list slot" do
    result = render_component do |c|
      c.with_diffs_list do
        'custom_list'
      end
    end
    expect(result).to have_text('custom_list')
  end

  it "renders diffs list" do
    render_component
    expect(page).to have_css('[data-diffs-list]')
    expect(page).to have_css('[data-diffs-overlay]')
  end

  it 'preloads' do
    render_component
    expect(component.helpers.page_startup_api_calls).to include(diffs_stats_endpoint)
    expect(component.helpers.page_startup_api_calls).to include(diff_files_endpoint)
    expect(vc_test_controller.view_context.content_for?(:startup_js)).not_to be_nil
  end

  it 'adds application stylesheet' do
    style_added = false
    allow(component).to receive(:helpers).and_wrap_original do |original_method, *args|
      helpers = original_method.call(*args)
      allow(helpers).to receive(:add_page_specific_style).with('page_bundles/rapid_diffs') do
        style_added = true
      end
      helpers
    end
    render_component
    expect(style_added).to be(true)
  end

  it 'has loading indicator' do
    render_component
    expect(page).to have_css('[data-list-loading]')
  end

  context 'when has no diffs for streaming' do
    let(:diffs_stream_url) { nil }

    it 'hides loading indicator' do
      render_component
      expect(page).to have_css('[data-list-loading][hidden]', visible: :hidden)
    end
  end

  context "when there are no diffs" do
    let(:diffs_slice) { [] }
    let(:diffs_stream_url) { nil }

    it "renders empty state component" do
      render_component
      expect(page).to have_text("There are no changes")
    end

    context 'when lazy loading' do
      let(:lazy) { true }

      it "does not render empty state" do
        render_component
        expect(page).not_to have_text("There are no changes")
      end
    end
  end

  def render_component(&block)
    render_inline(component, &block)
  end
end
