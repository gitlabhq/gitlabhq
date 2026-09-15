# frozen_string_literal: true

require "spec_helper"

RSpec.describe Blobs::EmailEmbeddedBlobComponent, feature_category: :markdown do
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

  it 'renders a table rather than the blob viewer gutter', :aggregate_failures do
    expect(page).to have_css('table.blob-embed')
    expect(page).not_to have_css('.line-numbers')
    expect(page).not_to have_css('.blob-content')
  end

  it 'renders the header with the file path and range', :aggregate_failures do
    expect(page).to have_css('.blob-embed-header .blob-embed-title', text: path)
    expect(page).to have_css('.blob-embed-header .blob-embed-range', text: 'Lines 3 to 6')
    expect(page.find('.blob-embed-title')[:href]).to end_with("/-/blob/#{sha}/#{path}#L3-6")
  end

  it 'renders one row per line, each pairing a number with its content', :aggregate_failures do
    numbers = page.all('td.blob-embed-num')
    expect(numbers.map { |cell| cell.text.strip }).to eq(%w[3 4 5 6])
    expect(numbers.first.find('a.blob-embed-num-link')[:href]).to end_with("/-/blob/#{sha}/#{path}#L3")

    expect(page).to have_css('td.blob-embed-line', count: 4)
    expect(page).to have_css('td.blob-embed-line span.line', count: 4)
  end

  it 'leaves no trailing newline inside a line cell' do
    contents = page.all('td.blob-embed-line').map { |cell| cell.native.inner_html }

    expect(contents).to all(match(/\S\z/))
  end

  context 'with a single line' do
    let(:from) { 4 }
    let(:to) { 4 }

    it 'labels a single line and renders one row', :aggregate_failures do
      expect(page).to have_css('.blob-embed-range', text: 'Line 4')
      expect(page).to have_css('td.blob-embed-line', count: 1)
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
