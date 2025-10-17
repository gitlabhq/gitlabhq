# frozen_string_literal: true

require "spec_helper"

RSpec.describe RapidDiffs::CommitAppComponent, feature_category: :code_review_workflow do
  let_it_be(:diffs_slice) { Array.new(2, build(:diff_file)) }
  let(:discussions_endpoint) { '/discussions' }
  let(:diffs_stream_url) { '/stream' }
  let(:reload_stream_url) { '/reload_stream' }
  let(:update_user_endpoint) { '/update_user' }
  let(:diffs_stats_endpoint) { '/diffs_stats' }
  let(:diff_files_endpoint) { '/diff_files_metadata' }
  let(:diff_file_endpoint) { '/diff_file' }
  let(:diff_view) { :inline }
  let(:should_sort_metadata_files) { false }
  let(:show_whitespace) { true }
  let(:lazy) { false }

  let(:diff_presenter) do
    instance_double(
      ::RapidDiffs::CommitPresenter,
      diffs_slice: diffs_slice,
      discussions_endpoint: discussions_endpoint,
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

  it "provides discussions_endpoint" do
    render_component
    app = page.find('[data-rapid-diffs]')
    data = Gitlab::Json.parse(app['data-app-data'])
    expect(data['discussions_endpoint']).to eq(discussions_endpoint)
  end

  it 'preloads discussions_endpoint' do
    render_component
    expect(component.helpers.page_startup_api_calls).to include(discussions_endpoint)
  end

  def render_component
    render_inline(component)
  end
end
