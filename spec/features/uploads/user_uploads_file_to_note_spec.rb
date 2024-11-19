# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User uploads file to note', feature_category: :text_editors do
  include DropzoneHelper

  let(:user) { create(:user) }
  let(:project) { create(:project, creator: user, namespace: user.namespace) }
  let(:issue) { create(:issue, project: project, author: user) }

  before do
    sign_in(user)
    visit project_issue_path(project, issue)
    wait_for_requests
  end

  context 'before uploading' do
    it 'shows "Attach a file or image" button', :js do
      expect(page).to have_selector('[data-testid="button-attach-file"]')
      expect(page).not_to have_selector('.uploading-progress-container', visible: true)
    end
  end

  context 'uploading is in progress', :capybara_ignore_server_errors do
    it 'cancels uploading on clicking to "Cancel" button', :js do
      slow_requests do
        dropzone_file([Rails.root.join('spec', 'fixtures', 'dk.png')], 0, false)

        click_button 'Cancel'
      end

      expect(page).to have_selector('[data-testid="button-attach-file"]')
      expect(page).not_to have_button('Cancel')
      expect(page).not_to have_selector('.uploading-progress-container', visible: true)
    end

    it 'shows "Attaching a file" message on uploading 1 file', :js do
      slow_requests do
        dropzone_file([Rails.root.join('spec', 'fixtures', 'dk.png')], 0, false)

        expect(page).to have_selector('.attaching-file-message', visible: true, text: 'Attaching a file -')
      end
    end

    it 'shows "Attaching 2 files" message on uploading 2 file', :js do
      slow_requests do
        dropzone_file([Rails.root.join('spec', 'fixtures', 'video_sample.mp4'),
                       Rails.root.join('spec', 'fixtures', 'dk.png')], 0, false)

        expect(page).to have_selector('.attaching-file-message', visible: true, text: 'Attaching 2 files -')
      end
    end

    it 'shows error message, "retry" and "attach a new file" link a if file is too big', :js do
      dropzone_file([Rails.root.join('spec', 'fixtures', 'video_sample.mp4')], 0.01)

      error_text = 'File is too big (0.06MiB). Max filesize: 0.01MiB.'

      expect(page).to have_selector('.uploading-error-message', visible: true, text: error_text)
      expect(page).to have_button('Try again', visible: true)
      expect(page).to have_button('attach a new file', visible: true)
    end
  end

  context 'uploading is complete' do
    it 'shows "Attach a file or image" button on uploading complete', :js do
      dropzone_file([Rails.root.join('spec', 'fixtures', 'dk.png')])
      wait_for_requests

      expect(page).to have_selector('[data-testid="button-attach-file"]')
      expect(page).not_to have_selector('.uploading-progress-container', visible: true)
    end

    it 'they see the attached file', :js do
      dropzone_file([Rails.root.join('spec', 'fixtures', 'dk.png')])
      click_button 'Comment'
      wait_for_requests

      expect(find('a.no-attachment-icon img.js-lazy-loaded[alt="dk"]')['src'])
        .to match(%r{/-/project/#{project.id}/uploads/\h{32}/dk\.png$})
    end
  end
end
