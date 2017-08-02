require 'rails_helper'

feature 'User uploads file to note' do
  include DropzoneHelper

  let(:user) { create(:user) }
  let(:project) { create(:empty_project, creator: user, namespace: user.namespace) }
  let(:issue) { create(:issue, project: project, author: user) }

  before do
    sign_in(user)
    visit project_issue_path(project, issue)
  end

  context 'before uploading' do
    it 'shows "Attach a file" button', js: true do
      expect(page).to have_button('Attach a file')
      expect(page).not_to have_selector('.uploading-progress-container', visible: true)
    end
  end

  context 'uploading is in progress' do
    it 'shows "Cancel" button on uploading', js: true do
      dropzone_file([Rails.root.join('spec', 'fixtures', 'dk.png')], 0, false)

      expect(page).to have_button('Cancel')
    end

    it 'cancels uploading on clicking to "Cancel" button', js: true do
      dropzone_file([Rails.root.join('spec', 'fixtures', 'dk.png')], 0, false)

      click_button 'Cancel'

      expect(page).to have_button('Attach a file')
      expect(page).not_to have_button('Cancel')
      expect(page).not_to have_selector('.uploading-progress-container', visible: true)
    end

    it 'shows "Attaching a file" message on uploading 1 file', js: true do
      dropzone_file([Rails.root.join('spec', 'fixtures', 'dk.png')], 0, false)

      expect(page).to have_selector('.attaching-file-message', visible: true, text: 'Attaching a file -')
    end

    it 'shows "Attaching 2 files" message on uploading 2 file', js: true do
      dropzone_file([Rails.root.join('spec', 'fixtures', 'video_sample.mp4'),
                     Rails.root.join('spec', 'fixtures', 'dk.png')], 0, false)

      expect(page).to have_selector('.attaching-file-message', visible: true, text: 'Attaching 2 files -')
    end

    it 'shows error message, "retry" and "attach a new file" link a if file is too big', js: true do
      dropzone_file([Rails.root.join('spec', 'fixtures', 'video_sample.mp4')], 0.01)

      error_text = 'File is too big (0.06MiB). Max filesize: 0.01MiB.'

      expect(page).to have_selector('.uploading-error-message', visible: true, text: error_text)
      expect(page).to have_selector('.retry-uploading-link', visible: true, text: 'Try again')
      expect(page).to have_selector('.attach-new-file', visible: true, text: 'attach a new file')
      expect(page).not_to have_button('Attach a file')
    end
  end

  context 'uploading is complete' do
    it 'shows "Attach a file" button on uploading complete', js: true do
      dropzone_file([Rails.root.join('spec', 'fixtures', 'dk.png')])
      wait_for_requests

      expect(page).to have_button('Attach a file')
      expect(page).not_to have_selector('.uploading-progress-container', visible: true)
    end

    scenario 'they see the attached file', js: true do
      dropzone_file([Rails.root.join('spec', 'fixtures', 'dk.png')])
      click_button 'Comment'
      wait_for_requests

      expect(find('a.no-attachment-icon img[alt="dk"]')['src'])
        .to match(%r{/#{project.full_path}/uploads/\h{32}/dk\.png$})
    end
  end
end
