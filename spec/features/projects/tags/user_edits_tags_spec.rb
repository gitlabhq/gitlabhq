# frozen_string_literal: true

require 'spec_helper'

describe 'Project > Tags', :js do
  include DropzoneHelper

  let(:user) { create(:user) }
  let(:role) { :developer }
  let(:project) { create(:project, :repository) }

  before do
    sign_in(user)
    project.add_role(user, role)
  end

  describe 'when opening project tags' do
    before do
      visit project_tags_path(project)
    end

    context 'page with tags list' do
      it 'shows tag name' do
        expect(page).to have_content 'v1.1.0 Version 1.1.0'
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
          page.find('.md-header-toolbar button.toolbar-btn:first-child').click

          expect(note_textarea.value).to eq('****')
        end
      end

      it 'release notes form shows "Attach a file" button', :js do
        page.within('.content form.release-form') do
          expect(page).to have_button('Attach a file')
          expect(page).not_to have_selector('.uploading-progress-container', visible: true)
        end
      end

      it 'shows "Attaching a file" message on uploading 1 file', :js do
        slow_requests do
          dropzone_file([Rails.root.join('spec', 'fixtures', 'dk.png')], 0, false)

          expect(page).to have_selector('.attaching-file-message', visible: true, text: 'Attaching a file -')
        end
      end
    end
  end
end
