# frozen_string_literal: true

require "spec_helper"

RSpec.describe RapidDiffs::AppComponent, type: :component, feature_category: :code_review_workflow do
  let(:diffs_slice) { Array.new(2) { build(:diff_file) } }
  let(:stream_url) { '/stream' }
  let(:reload_stream_url) { '/reload_stream' }
  let(:show_whitespace) { true }
  let(:diff_view) { 'inline' }
  let(:update_user_endpoint) { '/update_user' }
  let(:metadata_endpoint) { '/metadata' }

  it "renders diffs slice" do
    render_component
    expect(page.all('diff-file').size).to eq(2)
  end

  it "renders app data" do
    render_component
    app = page.find('[data-rapid-diffs]')
    expect(app).not_to be_nil
    expect(app['data-reload-stream-url']).to eq(reload_stream_url)
  end

  it "renders view settings" do
    render_component
    settings = page.find('[data-view-settings]')
    expect(settings).not_to be_nil
    expect(settings['data-show-whitespace']).to eq('true')
    expect(settings['data-diff-view-type']).to eq(diff_view)
    expect(settings['data-update-user-endpoint']).to eq(update_user_endpoint)
  end

  it "renders sidebar" do
    render_component
    container = page.find("[data-file-browser]")
    expect(container).not_to be_nil
    expect(container['data-metadata-endpoint']).to eq(metadata_endpoint)
  end

  it "sets sidebar width" do
    allow(vc_test_controller).to receive(:cookies).and_return({ mr_tree_list_width: '250' })
    render_component
    container = page.find("[data-file-browser]")
    expect(container[:style]).to include("width: 250px")
  end

  it "renders stream container" do
    render_component
    container = page.find("#js-stream-container")
    expect(container).not_to be_nil
    expect(container['data-diffs-stream-url']).to eq(stream_url)
  end

  def render_component
    render_inline(described_class.new(
      diffs_slice:,
      stream_url:,
      reload_stream_url:,
      show_whitespace:,
      diff_view:,
      update_user_endpoint:,
      metadata_endpoint:
    ))
  end
end
