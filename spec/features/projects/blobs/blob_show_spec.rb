require 'spec_helper'

feature 'File blob', feature: true do
  include TreeHelper

  let(:project) { create(:project, :public, :test_repo) }

  def visit_blob(path, fragment = nil)
    visit namespace_project_blob_path(project.namespace, project, tree_join('master', path), anchor: fragment)
  end

  context 'text files' do
    it 'shows rendered output for SVG' do
      visit_blob('files/images/wm.svg')

      expect(page).to have_selector('.blob-viewer[data-type="rich"]')
    end

    it 'switches to code view' do
      visit_blob('files/images/wm.svg')

      first('.js-blob-viewer-switch-btn').click

      expect(page).to have_selector('.blob-viewer[data-type="rich"]', visible: false)
      expect(page).to have_selector('.blob-viewer[data-type="simple"]')
    end

    it 'opens raw mode when linking to a line in SVG file' do
      visit_blob('files/images/wm.svg', 'L1')

      expect(page).to have_selector('#LC1.hll')
      expect(page).to have_selector('.blob-viewer[data-type="simple"]')
    end

    it 'opens raw mode when linking to a line in MD file' do
      visit_blob('README.md', 'L1')

      expect(page).to have_selector('#LC1.hll')
      expect(page).to have_selector('.blob-viewer[data-type="simple"]')
    end
  end

  context 'binary files' do
    it 'does not show view toggle buttons in toolbar' do
      visit_blob('Gemfile.zip')

      expect(first('.file-actions .btn-group')).to have_selector('.btn', count: 1)
      expect(first('.file-actions .btn-group .btn')[:title]).to eq('Download blob')
    end
  end
end
