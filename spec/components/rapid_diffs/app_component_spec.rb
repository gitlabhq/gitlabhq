# frozen_string_literal: true

require "spec_helper"

RSpec.describe RapidDiffs::AppComponent, type: :component, feature_category: :code_review_workflow do
  let(:diffs_slice) { Array.new(2) { build(:diff_file) } }
  let(:stream_url) { '/stream' }
  let(:reload_stream_url) { '/reload_stream' }
  let(:show_whitespace) { true }
  let(:diff_view) { 'inline' }
  let(:update_user_endpoint) { '/update_user' }
  let(:diffs_stats_endpoint) { '/diffs_stats' }
  let(:diff_files_endpoint) { '/diff_files_metadata' }

  it "renders diffs slice" do
    render_component
    expect(page.all('diff-file').size).to eq(2)
  end

  it "renders app data" do
    render_component
    app = page.find('[data-rapid-diffs]')
    expect(app).not_to be_nil
    expect(app['data-reload-stream-url']).to eq(reload_stream_url)
    expect(app['data-diffs-stats-endpoint']).to eq(diffs_stats_endpoint)
    expect(app['data-diff-files-endpoint']).to eq(diff_files_endpoint)
  end

  it "renders view settings" do
    render_component
    settings = page.find('[data-view-settings]')
    expect(settings).not_to be_nil
    expect(settings['data-show-whitespace']).to eq('true')
    expect(settings['data-diff-view-type']).to eq(diff_view)
    expect(settings['data-update-user-endpoint']).to eq(update_user_endpoint)
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
    container = page.find("#js-stream-container")
    expect(container).not_to be_nil
    expect(container['data-diffs-stream-url']).to eq(stream_url)
  end

  it "renders diffs_list slot" do
    result = render_component do |c|
      c.with_diffs_list do
        'custom_list'
      end
    end
    expect(result).to have_text('custom_list')
  end

  it 'preloads' do
    instance = create_instance
    render_inline(instance)
    expect(instance.helpers.page_startup_api_calls).to include(diffs_stats_endpoint)
    expect(instance.helpers.page_startup_api_calls).to include(diff_files_endpoint)
    expect(vc_test_controller.view_context.content_for?(:startup_js)).not_to be_nil
  end

  context "when there are no diffs" do
    let(:diffs_slice) { [] }

    it "renders empty state component" do
      render_component
      expect(page).to have_text("There are no changes")
    end

    it "does not render empty state when lazy is true" do
      instance = create_instance(lazy: true)
      render_inline(instance)
      expect(page).not_to have_text("There are no changes")
    end
  end

  def create_instance(lazy: false)
    described_class.new(
      diffs_slice:,
      stream_url:,
      reload_stream_url:,
      show_whitespace:,
      diff_view:,
      update_user_endpoint:,
      diffs_stats_endpoint:,
      diff_files_endpoint:,
      lazy:
    )
  end

  def render_component(&block)
    render_inline(create_instance, &block)
  end
end
