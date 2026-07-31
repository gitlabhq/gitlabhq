# frozen_string_literal: true

require "spec_helper"

RSpec.describe Blobs::EmbeddedBlobComponent, feature_category: :markdown do
  # A real repository is required to fetch and highlight blob content.
  let_it_be(:project) { create(:project, :repository) } # rubocop:disable RSpec/FactoryBot/AvoidCreate -- needs a real repository

  let(:sha) { project.commit.sha }
  let(:path) { 'files/ruby/popen.rb' }
  let(:blob) { project.repository.blob_at(sha, path).present }
  let(:from) { 3 }
  let(:to) { 6 }
  let(:cross_project) { false }

  before do
    render_inline(
      described_class.new(blob: blob, project: project, sha: sha, from: from, to: to, cross_project: cross_project)
    )
  end

  it 'renders the card chrome with the file path and range', :aggregate_failures do
    expect(page).to have_css('.blob-embed .file-content.code.code-syntax-highlight-theme')
    expect(page).to have_css('.blob-embed-title', text: path)
    expect(page).to have_css('.blob-embed-range', text: 'Lines 3 to 6')
  end

  it 'renders the highlighted window with no line IDs' do
    expect(page).to have_css('.blob-content code span.line', count: 4)
    expect(page).not_to have_css('.blob-content code span.line[id]')
  end

  it 'links the title and each gutter line to the permalink' do
    expect(page.find('.blob-embed-title')[:href]).to end_with("/-/blob/#{sha}/#{path}#L3-6")

    gutter = page.all('.line-numbers a.diff-line-num')
    expect(gutter.map(&:text)).to eq(%w[3 4 5 6])
    expect(gutter.first[:href]).to end_with("/-/blob/#{sha}/#{path}#L3")
  end

  context 'with a single line' do
    let(:from) { 4 }
    let(:to) { 4 }

    it 'labels a single line and renders one row' do
      expect(page).to have_css('.blob-embed-range', text: 'Line 4')
      expect(page).to have_css('.blob-content code span.line', count: 1)
      expect(page.find('.blob-embed-title')[:href]).to end_with("#L4")
    end
  end

  context 'when cross-project' do
    let(:cross_project) { true }

    it 'qualifies the title with the project full path' do
      expect(page).to have_css('.blob-embed-title', text: "#{project.full_path}/#{path}")
    end
  end
end
