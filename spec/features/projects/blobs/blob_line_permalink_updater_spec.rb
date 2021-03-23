# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Blob button line permalinks (BlobLinePermalinkUpdater)', :js do
  include TreeHelper

  let(:project) { create(:project, :public, :repository) }
  let(:path) { 'CHANGELOG' }
  let(:sha) { project.repository.commit.sha }

  describe 'On a file(blob)' do
    def get_absolute_url(path = "")
      "http://#{page.server.host}:#{page.server.port}#{path}"
    end

    def visit_blob(fragment = nil)
      visit project_blob_path(project, tree_join('master', path), anchor: fragment)
    end

    describe 'Click "Permalink" button' do
      it 'works with no initial line number fragment hash' do
        visit_blob

        expect(find('.js-data-file-blob-permalink-url')['href']).to eq(get_absolute_url(project_blob_path(project, tree_join(sha, path))))
      end

      it 'maintains intitial fragment hash' do
        fragment = "L3"

        visit_blob(fragment)

        expect(find('.js-data-file-blob-permalink-url')['href']).to eq(get_absolute_url(project_blob_path(project, tree_join(sha, path), anchor: fragment)))
      end

      it 'changes fragment hash if line number clicked' do
        ending_fragment = "L5"

        visit_blob

        find('#L3').click
        find("##{ending_fragment}").click

        expect(find('.js-data-file-blob-permalink-url')['href']).to eq(get_absolute_url(project_blob_path(project, tree_join(sha, path), anchor: ending_fragment)))
      end

      it 'with initial fragment hash, changes fragment hash if line number clicked' do
        fragment = "L1"
        ending_fragment = "L5"

        visit_blob(fragment)

        find('#L3').click
        find("##{ending_fragment}").click

        expect(find('.js-data-file-blob-permalink-url')['href']).to eq(get_absolute_url(project_blob_path(project, tree_join(sha, path), anchor: ending_fragment)))
      end
    end

    describe 'Click "Blame" button' do
      it 'works with no initial line number fragment hash' do
        visit_blob

        expect(find('.js-blob-blame-link')['href']).to eq(get_absolute_url(project_blame_path(project, tree_join('master', path))))
      end

      it 'maintains intitial fragment hash' do
        fragment = "L3"

        visit_blob(fragment)

        expect(find('.js-blob-blame-link')['href']).to eq(get_absolute_url(project_blame_path(project, tree_join('master', path), anchor: fragment)))
      end

      it 'changes fragment hash if line number clicked' do
        ending_fragment = "L5"

        visit_blob

        find('#L3').click
        find("##{ending_fragment}").click

        expect(find('.js-blob-blame-link')['href']).to eq(get_absolute_url(project_blame_path(project, tree_join('master', path), anchor: ending_fragment)))
      end

      it 'with initial fragment hash, changes fragment hash if line number clicked' do
        fragment = "L1"
        ending_fragment = "L5"

        visit_blob(fragment)

        find('#L3').click
        find("##{ending_fragment}").click

        expect(find('.js-blob-blame-link')['href']).to eq(get_absolute_url(project_blame_path(project, tree_join('master', path), anchor: ending_fragment)))
      end
    end
  end
end
