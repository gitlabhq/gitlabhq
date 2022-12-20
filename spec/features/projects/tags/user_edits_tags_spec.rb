# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Project > Tags', :js, feature_category: :source_code_management do
  include DropzoneHelper

  let_it_be(:user) { create(:user) }
  let_it_be(:role) { :developer }
  let_it_be(:project) { create(:project, :repository) }

  before do
    sign_in(user)
    project.add_role(user, role)
  end

  shared_examples "can create and update release" do
    it 'shows tag information' do
      visit page_url

      expect(page).to have_content 'v1.1.0'
      expect(page).to have_content 'Version 1.1.0'
    end

    it 'can create new release' do
      visit page_url
      page.find("a[href=\"#{new_project_release_path(project, tag_name: 'v1.1.0')}\"]").click

      fill_in "Release notes", with: "new release from tag"
      expect(page).not_to have_field("Create from")
      click_button "Create release"

      expect(page).to have_current_path(project_release_path(project, 'v1.1.0'))
      expect(Release.last.description).to eq("new release from tag")
    end

    it 'can edit existing release' do
      release = create(:release, project: project, tag: 'v1.1.0')

      visit page_url
      page.find("a[href=\"#{edit_project_release_path(project, release)}\"]").click

      fill_in "Release notes", with: "updated release desc"
      click_button "Save changes"

      expect(page).to have_current_path(project_release_path(project, 'v1.1.0'))
      expect(release.reload.description).to eq("updated release desc")
    end
  end

  context 'when visiting tags index page' do
    let(:page_url) { project_tags_path(project) }

    include_examples "can create and update release"
  end

  context 'when visiting individual tag page' do
    let(:page_url) { project_tag_path(project, 'v1.1.0') }

    include_examples "can create and update release"
  end
end
