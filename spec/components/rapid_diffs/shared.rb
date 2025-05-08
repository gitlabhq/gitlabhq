# frozen_string_literal: true

require "spec_helper"

RSpec.shared_context "with diff file component tests" do
  let(:web_component_selector) { 'diff-file' }
  let(:web_component) { page.find(web_component_selector) }
  let(:diff_file) { build(:diff_file) }
  let(:repository) { diff_file.repository }
  let(:project) { repository.container }
  let(:namespace) { project.namespace }
  let(:sample_commit) { instance_double(Commit, raw_diffs: [diff_file]) }

  before do
    allow(repository).to receive(:commit).with(RepoHelpers.sample_commit.id).and_return(sample_commit)
  end

  # This should be overridden in the including spec
  def render_component
    raise "Override render_component in the including spec"
  end

  it "renders" do
    render_component
    expect(page).to have_selector(web_component_selector)
    expect(page).to have_selector("#{web_component_selector}-mounted")
  end

  it "renders server data" do
    render_component
    diff_path = "/#{namespace.to_param}/#{project.to_param}/-/blob/#{diff_file.content_sha}/#{diff_file.file_path}"
    expect(file_data['diff_lines_path']).to eq("#{diff_path}/diff_lines")
  end

  it "renders line count" do
    render_component
    total_count = web_component.all(:css, 'table tbody tr').count
    expect(web_component).to have_css("[style~='--total-rows: #{total_count}']")
  end

  it "enables virtual rendering" do
    render_component
    expect(web_component).to have_css("[data-virtual]")
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
        expect(file_data['viewer']).to eq('no_preview')
      end
    end

    it "renders inline text viewer" do
      render_component
      expect(file_data['viewer']).to eq('text_inline')
    end

    it "renders parallel text viewer" do
      render_component(parallel_view: true)
      expect(file_data['viewer']).to eq('text_parallel')
    end
  end

  context "when no viewer found" do
    before do
      allow(diff_file).to receive_messages(text?: false, content_changed?: false)
    end

    it "renders no preview" do
      render_component
      expect(file_data['viewer']).to eq('no_preview')
    end

    it "disables virtual rendering" do
      render_component
      expect(web_component).not_to have_css("[data-virtual]")
    end
  end

  context "when file is collapsed" do
    before do
      allow(diff_file).to receive(:collapsed?).and_return(true)
    end

    it "renders no preview" do
      render_component
      expect(file_data['viewer']).to eq('no_preview')
    end

    it "disables virtual rendering" do
      render_component
      expect(web_component).not_to have_css("[data-virtual]")
    end
  end

  def file_data
    Gitlab::Json.parse(web_component['data-file-data'])
  end
end
