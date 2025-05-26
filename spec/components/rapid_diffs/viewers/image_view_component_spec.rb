# frozen_string_literal: true

require "spec_helper"

RSpec.describe RapidDiffs::Viewers::ImageViewComponent, type: :component, feature_category: :code_review_workflow do
  let_it_be(:diff_file) { build(:diff_file) }
  let(:viewer) { page.find('[data-image-data]') }

  before do
    allow(diff_file).to receive_message_chain(:old_blob, :size).and_return('200')
    allow(diff_file).to receive_message_chain(:new_blob, :size).and_return('300')
  end

  it 'provides image diff data' do
    render_component
    project = diff_file.repository.container
    namespace = project.namespace
    old_path = "/#{namespace.to_param}/#{project.to_param}/-/raw/#{diff_file.old_content_sha}/#{diff_file.file_path}"
    new_path = "/#{namespace.to_param}/#{project.to_param}/-/raw/#{diff_file.content_sha}/#{diff_file.file_path}"
    expect(image_data).to eq({
      "old_path" => old_path,
      "new_path" => new_path,
      "old_size" => '200',
      "new_size" => '300',
      "diff_mode" => 'replaced'
    })
  end

  it 'renders image app mount element' do
    render_component
    expect(page).to have_css('[data-image-view]')
  end

  def image_data
    Gitlab::Json.parse(viewer['data-image-data'])
  end

  def render_component(**args)
    render_inline(described_class.new(diff_file: diff_file, **args))
  end
end
