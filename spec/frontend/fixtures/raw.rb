# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Raw files', '(JavaScript fixtures)' do
  include JavaScriptFixturesHelpers

  let(:namespace) { create(:namespace, name: 'frontend-fixtures' )}
  let(:project) { create(:project, :repository, namespace: namespace, path: 'raw-project') }
  let(:response) { @blob.data.force_encoding('UTF-8') }

  before(:all) do
    clean_frontend_fixtures('blob/notebook/')
    clean_frontend_fixtures('blob/pdf/')
    clean_frontend_fixtures('blob/text/')
    clean_frontend_fixtures('blob/binary/')
    clean_frontend_fixtures('blob/images/')
  end

  after do
    remove_repository(project)
  end

  it 'blob/notebook/basic.json' do
    @blob = project.repository.blob_at('6d85bb69', 'files/ipython/basic.ipynb')
  end

  it 'blob/notebook/markdown-table.json' do
    @blob = project.repository.blob_at('f6b7a707', 'files/ipython/markdown-table.ipynb')
  end

  it 'blob/notebook/worksheets.json' do
    @blob = project.repository.blob_at('6d85bb69', 'files/ipython/worksheets.ipynb')
  end

  it 'blob/notebook/math.json' do
    @blob = project.repository.blob_at('93ee732', 'files/ipython/math.ipynb')
  end

  it 'blob/pdf/test.pdf' do
    @blob = project.repository.blob_at('e774ebd33', 'files/pdf/test.pdf')
  end

  it 'blob/text/README.md' do
    @blob = project.repository.blob_at('e774ebd33', 'README.md')
  end

  it 'blob/images/logo-white.png' do
    @blob = project.repository.blob_at('e774ebd33', 'files/images/logo-white.png')
  end

  it 'blob/binary/Gemfile.zip' do
    @blob = project.repository.blob_at('e774ebd33', 'Gemfile.zip')
  end
end
