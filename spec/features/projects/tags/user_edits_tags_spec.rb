# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Project > Tags', :js do
  include DropzoneHelper

  let_it_be(:user) { create(:user) }
  let_it_be(:role) { :developer }
  let_it_be(:project) { create(:project, :repository) }

  before do
    sign_in(user)
    project.add_role(user, role)
  end

  shared_examples "can create and update release" do
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

  # TODO: remove most of these together with FF https://gitlab.com/gitlab-org/gitlab/-/issues/366244
  describe 'when opening project tags' do
    before do
      stub_feature_flags(edit_tag_release_notes_via_release_page: false)
      visit project_tags_path(project)
    end

    context 'page with tags list' do
      it 'shows tag name' do
        expect(page).to have_content 'v1.1.0'
        expect(page).to have_content 'Version 1.1.0'
      end

      it 'shows tag edit button' do
        page.within '.tags > .content-list' do
          edit_btn = page.find("li > .row-fixed-content.controls a.btn-edit[href='/#{project.full_path}/-/tags/v1.1.0/release/edit']")

          expect(edit_btn['href']).to end_with("/#{project.full_path}/-/tags/v1.1.0/release/edit")
        end
      end
    end

    context 'edit tag release notes' do
      before do
        page.find("li > .row-fixed-content.controls a.btn-edit[href='/#{project.full_path}/-/tags/v1.1.0/release/edit']").click
      end

      it 'shows tag name header' do
        page.within('.content') do
          expect(page.find('.sub-header-block')).to have_content 'Release notes for tag v1.1.0'
        end
      end

      it 'shows release notes form' do
        page.within('.content') do
          expect(page).to have_selector('form.release-form')
        end
      end

      it 'toolbar buttons on release notes form are functional' do
        page.within('.content form.release-form') do
          note_textarea = page.find('.js-gfm-input')

          # Click on Bold button
          page.find('.md-header-toolbar button:first-child').click

          expect(note_textarea.value).to eq('****')
        end
      end

      it 'release notes form shows "Attach a file" button', :js do
        page.within('.content form.release-form') do
          expect(page).to have_button('Attach a file')
          expect(page).not_to have_selector('.uploading-progress-container', visible: true)
        end
      end

      it 'shows "Attaching a file" message on uploading 1 file', :js, :capybara_ignore_server_errors do
        slow_requests do
          dropzone_file([Rails.root.join('spec', 'fixtures', 'dk.png')], 0, false)

          expect(page).to have_selector('.attaching-file-message', visible: true, text: 'Attaching a file -')
        end
      end
    end
  end
end
