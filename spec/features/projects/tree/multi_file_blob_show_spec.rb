require 'spec_helper'

feature 'File blob', :js do
  let(:project) { create(:project, :public, :repository) }

  def visit_blob(path, file: '', anchor: nil, ref: 'master')
    visit project_tree_path(project, File.join(ref, path), anchor: anchor)

    wait_for_requests

    click_link file

    wait_for_requests
  end

  before do
    set_cookie('new_repo', 'true')
  end

  context 'Ruby file' do
    before do
      visit_blob('files/ruby', file: 'popen.rb')
    end

    it 'displays the blob' do
      aggregate_failures do
        # shows highlighted Ruby code
        expect(page).to have_css(".js-syntax-highlight")
        expect(page).to have_content("require 'fileutils'")

        # does not show a viewer switcher
        expect(page).not_to have_selector('.js-blob-viewer-switcher')

        # shows an enabled copy button
        expect(page).to have_selector('.js-copy-blob-source-btn:not(.disabled)')

        # shows a raw button
        expect(page).to have_selector('a[data-original-title="Open raw"]')
      end
    end
  end

  context 'Markdown file' do
    context 'visiting directly' do
      before do
        visit_blob('files/markdown', file: 'ruby-style-guide.md')
      end

      it 'displays the blob using the rich viewer' do
        aggregate_failures do
          # hides the simple viewer
          expect(page).not_to have_selector('.blob-viewer[data-type="simple"]')
          expect(page).to have_selector('.blob-viewer[data-type="rich"]')

          # shows rendered Markdown
          expect(page).to have_link("PEP-8")

          # shows a viewer switcher
          expect(page).to have_selector('.js-blob-viewer-switcher')

          # shows a disabled copy button
          expect(page).to have_selector('.js-copy-blob-source-btn.disabled')

          # shows a raw button
          expect(page).to have_selector('a[data-original-title="Open raw"]')
        end
      end

      context 'switching to the simple viewer' do
        before do
          find('.js-blob-viewer-switch-btn[data-viewer=simple]').click

          wait_for_requests
        end

        it 'displays the blob using the simple viewer' do
          aggregate_failures do
            # hides the rich viewer
            expect(page).to have_selector('.blob-viewer[data-type="simple"]')
            expect(page).not_to have_selector('.blob-viewer[data-type="rich"]')

            # shows highlighted Markdown code
            expect(page).to have_css(".js-syntax-highlight")
            expect(page).to have_content("[PEP-8](http://www.python.org/dev/peps/pep-0008/)")

            # shows an enabled copy button
            expect(page).to have_selector('.js-copy-blob-source-btn:not(.disabled)')
          end
        end

        context 'switching to the rich viewer again' do
          before do
            find('.js-blob-viewer-switch-btn[data-viewer=rich]').click

            wait_for_requests
          end

          it 'displays the blob using the rich viewer' do
            aggregate_failures do
              # hides the simple viewer
              expect(page).not_to have_selector('.blob-viewer[data-type="simple"]')
              expect(page).to have_selector('.blob-viewer[data-type="rich"]')

              # shows an enabled copy button
              expect(page).to have_selector('.js-copy-blob-source-btn:not(.disabled)')
            end
          end
        end
      end
    end
  end

  context 'Markdown file (stored in LFS)' do
    before do
      project.add_master(project.creator)

      Files::CreateService.new(
        project,
        project.creator,
        start_branch: 'master',
        branch_name: 'master',
        commit_message: "Add Markdown in LFS",
        file_path: 'files/lfs/file.md',
        file_content: project.repository.blob_at('master', 'files/lfs/lfs_object.iso').data
      ).execute
    end

    context 'when LFS is enabled on the project' do
      before do
        allow(Gitlab.config.lfs).to receive(:enabled).and_return(true)
        project.update_attribute(:lfs_enabled, true)

        visit_blob('files/lfs', file: 'file.md')
      end

      it 'displays an error' do
        aggregate_failures do
          # shows an error message
          expect(page).to have_content('The rendered file could not be displayed because it is stored in LFS. You can download it instead.')

          # shows a viewer switcher
          expect(page).to have_selector('.js-blob-viewer-switcher')

          # does not show a copy button
          expect(page).not_to have_selector('.js-copy-blob-source-btn')

          # shows a download button
          expect(page).to have_selector('a[data-original-title="Download"]')
        end
      end

      context 'switching to the simple viewer' do
        before do
          find('.js-blob-viewer-switcher .js-blob-viewer-switch-btn[data-viewer=simple]').click

          wait_for_requests
        end

        it 'displays an error' do
          aggregate_failures do
            # shows an error message
            expect(page).to have_content('The source could not be displayed because it is stored in LFS. You can download it instead.')

            # does not show a copy button
            expect(page).not_to have_selector('.js-copy-blob-source-btn')
          end
        end
      end
    end

    context 'when LFS is disabled on the project' do
      before do
        visit_blob('files/lfs', file: 'file.md')
      end

      it 'displays the blob' do
        aggregate_failures do
          # does not show a viewer switcher
          expect(page).not_to have_selector('.js-blob-viewer-switcher')

          # shows an enabled copy button
          expect(page).to have_selector('.js-copy-blob-source-btn:not(.disabled)')

          # shows a raw button
          expect(page).to have_selector('a[data-original-title="Open raw"]')
        end
      end
    end
  end

  xcontext 'PDF file' do
    before do
      project.add_master(project.creator)

      Files::CreateService.new(
        project,
        project.creator,
        start_branch: 'master',
        branch_name: 'master',
        commit_message: "Add PDF",
        file_path: 'files/test.pdf',
        file_content: project.repository.blob_at('add-pdf-file', 'files/pdf/test.pdf').data
      ).execute

      visit_blob('files', file: 'test.pdf')
    end

    it 'displays the blob' do
      aggregate_failures do
        # shows rendered PDF
        expect(page).to have_selector('.js-pdf-viewer')

        # does not show a viewer switcher
        expect(page).not_to have_selector('.js-blob-viewer-switcher')

        # does not show a copy button
        expect(page).not_to have_selector('.js-copy-blob-source-btn')

        # shows a download button
        expect(page).to have_selector('a[data-original-title="Download"]')
      end
    end
  end

  context 'ISO file (stored in LFS)' do
    context 'when LFS is enabled on the project' do
      before do
        allow(Gitlab.config.lfs).to receive(:enabled).and_return(true)
        project.update_attribute(:lfs_enabled, true)

        visit_blob('files/lfs', file: 'lfs_object.iso')
      end

      it 'displays the blob' do
        aggregate_failures do
          # shows a download link
          expect(page).to have_link('Download (1.5 MB)')

          # does not show a viewer switcher
          expect(page).not_to have_selector('.js-blob-viewer-switcher')

          # does not show a copy button
          expect(page).not_to have_selector('.js-copy-blob-source-btn')

          # shows a download button
          expect(page).to have_selector('a[data-original-title="Download"]')
        end
      end
    end

    context 'when LFS is disabled on the project' do
      before do
        visit_blob('files/lfs', file: 'lfs_object.iso')
      end

      it 'displays the blob' do
        aggregate_failures do
          # does not show a viewer switcher
          expect(page).not_to have_selector('.js-blob-viewer-switcher')

          # shows an enabled copy button
          expect(page).to have_selector('.js-copy-blob-source-btn:not(.disabled)')

          # shows a raw button
          expect(page).to have_selector('a[data-original-title="Open raw"]')
        end
      end
    end
  end

  context 'ZIP file' do
    before do
      visit_blob('', file: 'Gemfile.zip')
    end

    it 'displays the blob' do
      aggregate_failures do
        # shows a download link
        expect(page).to have_link('Download (2.11 KB)')

        # does not show a viewer switcher
        expect(page).not_to have_selector('.js-blob-viewer-switcher')

        # does not show a copy button
        expect(page).not_to have_selector('.js-copy-blob-source-btn')

        # shows a download button
        expect(page).to have_selector('a[data-original-title="Download"]')
      end
    end
  end

  context 'empty file' do
    before do
      project.add_master(project.creator)

      Files::CreateService.new(
        project,
        project.creator,
        start_branch: 'master',
        branch_name: 'master',
        commit_message: "Add empty file",
        file_path: 'files/empty.md',
        file_content: ''
      ).execute

      visit_blob('files', file: 'empty.md')
    end

    it 'displays an error' do
      aggregate_failures do
        # shows an error message
        expect(page).to have_content('Empty file')

        # does not show a viewer switcher
        expect(page).not_to have_selector('.js-blob-viewer-switcher')

        # does not show a copy button
        expect(page).not_to have_selector('.js-copy-blob-source-btn')

        # does not show a download or raw button
        expect(page).not_to have_selector('a[data-original-title="Download"]')
      end
    end
  end

  context 'binary file that appears to be text in the first 1024 bytes' do
    before do
      visit_blob('encoding', file: 'binary-1.bin', ref: 'binary-encoding')
    end

    it 'displays the blob' do
      aggregate_failures do
        # shows a download link
        expect(page).to have_link('Download (23.8 KB)')

        # does not show a viewer switcher
        expect(page).not_to have_selector('.js-blob-viewer-switcher')

        # The specs below verify an arguably incorrect result, but since we only
        # learn that the file is not actually text once the text viewer content
        # is loaded asynchronously, there is no straightforward way to get these
        # synchronously loaded elements to display correctly.
        #
        # Clicking the copy button will result in nothing being copied.
        # Clicking the raw button will result in the binary file being downloaded,
        # as expected.

        # shows an enabled copy button, incorrectly
        expect(page).to have_selector('.js-copy-blob-source-btn:not(.disabled)')

        # shows a raw button, incorrectly
        expect(page).to have_selector('a[data-original-title="Open raw"]')
      end
    end
  end
end
