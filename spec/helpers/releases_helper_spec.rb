# frozen_string_literal: true

require 'spec_helper'

describe ReleasesHelper do
  describe '#illustration' do
    it 'returns the correct image path' do
      expect(helper.illustration).to match(/illustrations\/releases-(\w+)\.svg/)
    end
  end

  describe '#help_page' do
    it 'returns the correct link to the help page' do
      expect(helper.help_page).to include('user/project/releases/index')
    end
  end

  context 'url helpers' do
    let(:project) { build(:project, namespace: create(:group)) }
    let(:release) { create(:release, project: project) }

    before do
      helper.instance_variable_set(:@project, project)
      helper.instance_variable_set(:@release, release)
    end

    describe '#data_for_releases_page' do
      it 'has the needed data to display release blocks' do
        keys = %i(project_id illustration_path documentation_path)
        expect(helper.data_for_releases_page.keys).to eq(keys)
      end
    end

    describe '#data_for_edit_release_page' do
      it 'has the needed data to display the "edit release" page' do
        keys = %i(project_id
                  tag_name
                  markdown_preview_path
                  markdown_docs_path
                  releases_page_path
                  update_release_api_docs_path)
        expect(helper.data_for_edit_release_page.keys).to eq(keys)
      end
    end
  end
end
