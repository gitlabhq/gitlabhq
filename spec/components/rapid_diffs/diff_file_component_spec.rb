# frozen_string_literal: true

require "spec_helper"

RSpec.describe RapidDiffs::DiffFileComponent, type: :component, feature_category: :code_review_workflow do
  let_it_be(:diff_file) { build(:diff_file) }
  let(:repository) { diff_file.repository }
  let(:project) { repository.container }
  let(:namespace) { project.namespace }
  let(:web_component) { page.find('diff-file') }

  it "renders" do
    render_component
    expect(page).to have_selector('diff-file')
    expect(page).to have_selector('diff-file-mounted')
  end

  it "renders server data" do
    render_component
    diff_path = "/#{namespace.to_param}/#{project.to_param}/-/blob/#{diff_file.content_sha}/#{diff_file.file_path}/diff"
    expect(web_component['data-blob-diff-path']).to eq(diff_path)
  end

  context "when is text diff" do
    before do
      allow(diff_file).to receive(:diffable_text?).and_return(true)
    end

    context "when file is not modified" do
      before do
        allow(diff_file).to receive(:modified_file?).and_return(false)
      end

      it "renders no preview" do
        render_component
        expect(web_component['data-viewer']).to eq('no_preview')
      end
    end

    it "renders parallel text viewer" do
      render_component
      expect(web_component['data-viewer']).to eq('text_inline')
    end

    it "renders parallel text viewer" do
      render_component(parallel_view: true)
      expect(web_component['data-viewer']).to eq('text_parallel')
    end
  end

  context "when no viewer found" do
    before do
      allow(diff_file).to receive(:text?).and_return(false)
      allow(diff_file).to receive(:content_changed?).and_return(false)
    end

    it "renders no preview" do
      render_component
      expect(web_component['data-viewer']).to eq('no_preview')
    end
  end

  context "when file is collapsed" do
    before do
      allow(diff_file).to receive(:collapsed?).and_return(true)
    end

    it "renders no preview" do
      render_component
      expect(web_component['data-viewer']).to eq('no_preview')
    end
  end

  def render_component(**args)
    render_inline(described_class.new(diff_file: diff_file, **args))
  end
end
