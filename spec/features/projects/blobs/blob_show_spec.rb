require 'spec_helper'

feature 'File blob', :js, feature: true do
  let(:project) { create(:project, :public) }

  def visit_blob(path, fragment = nil)
    visit namespace_project_blob_path(project.namespace, project, File.join('master', path), anchor: fragment)
  end

  context 'Ruby file' do
    before do
      visit_blob('files/ruby/popen.rb')

      wait_for_ajax
    end

    it 'displays the blob' do
      aggregate_failures do
        # shows highlighted Ruby code
        expect(page).to have_content("require 'fileutils'")

        # does not show a viewer switcher
        expect(page).not_to have_selector('.js-blob-viewer-switcher')

        # shows an enabled copy button
        expect(page).to have_selector('.js-copy-blob-source-btn:not(.disabled)')

        # shows a raw button
        expect(page).to have_link('Open raw')
      end
    end
  end

  context 'Markdown file' do
    context 'visiting directly' do
      before do
        visit_blob('files/markdown/ruby-style-guide.md')

        wait_for_ajax
      end

      it 'displays the blob using the rich viewer' do
        aggregate_failures do
          # hides the simple viewer
          expect(page).to have_selector('.blob-viewer[data-type="simple"]', visible: false)
          expect(page).to have_selector('.blob-viewer[data-type="rich"]')

          # shows rendered Markdown
          expect(page).to have_link("PEP-8")

          # shows a viewer switcher
          expect(page).to have_selector('.js-blob-viewer-switcher')

          # shows a disabled copy button
          expect(page).to have_selector('.js-copy-blob-source-btn.disabled')

          # shows a raw button
          expect(page).to have_link('Open raw')
        end
      end

      context 'switching to the simple viewer' do
        before do
          find('.js-blob-viewer-switch-btn[data-viewer=simple]').click

          wait_for_ajax
        end

        it 'displays the blob using the simple viewer' do
          aggregate_failures do
            # hides the rich viewer
            expect(page).to have_selector('.blob-viewer[data-type="simple"]')
            expect(page).to have_selector('.blob-viewer[data-type="rich"]', visible: false)

            # shows highlighted Markdown code
            expect(page).to have_content("[PEP-8](http://www.python.org/dev/peps/pep-0008/)")

            # shows an enabled copy button
            expect(page).to have_selector('.js-copy-blob-source-btn:not(.disabled)')
          end
        end

        context 'switching to the rich viewer again' do
          before do
            find('.js-blob-viewer-switch-btn[data-viewer=rich]').click

            wait_for_ajax
          end

          it 'displays the blob using the rich viewer' do
            aggregate_failures do
              # hides the simple viewer
              expect(page).to have_selector('.blob-viewer[data-type="simple"]', visible: false)
              expect(page).to have_selector('.blob-viewer[data-type="rich"]')

              # shows an enabled copy button
              expect(page).to have_selector('.js-copy-blob-source-btn:not(.disabled)')
            end
          end
        end
      end
    end

    context 'visiting with a line number anchor' do
      before do
        visit_blob('files/markdown/ruby-style-guide.md', 'L1')

        wait_for_ajax
      end

      it 'displays the blob using the simple viewer' do
        aggregate_failures do
          # hides the rich viewer
          expect(page).to have_selector('.blob-viewer[data-type="simple"]')
          expect(page).to have_selector('.blob-viewer[data-type="rich"]', visible: false)

          # highlights the line in question
          expect(page).to have_selector('#LC1.hll')

          # shows highlighted Markdown code
          expect(page).to have_content("[PEP-8](http://www.python.org/dev/peps/pep-0008/)")

          # shows an enabled copy button
          expect(page).to have_selector('.js-copy-blob-source-btn:not(.disabled)')
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

        visit_blob('files/lfs/file.md')

        wait_for_ajax
      end

      it 'displays an error' do
        aggregate_failures do
          # hides the simple viewer
          expect(page).to have_selector('.blob-viewer[data-type="simple"]', visible: false)
          expect(page).to have_selector('.blob-viewer[data-type="rich"]')

          # shows an error message
          expect(page).to have_content('The rendered file could not be displayed because it is stored in LFS. You can view the source or download it instead.')

          # shows a viewer switcher
          expect(page).to have_selector('.js-blob-viewer-switcher')

          # does not show a copy button
          expect(page).not_to have_selector('.js-copy-blob-source-btn')

          # shows a raw button
          expect(page).to have_link('Open raw')
        end
      end

      context 'switching to the simple viewer' do
        before do
          find('.js-blob-viewer-switcher .js-blob-viewer-switch-btn[data-viewer=simple]').click

          wait_for_ajax
        end

        it 'displays an error' do
          aggregate_failures do
            # hides the rich viewer
            expect(page).to have_selector('.blob-viewer[data-type="simple"]')
            expect(page).to have_selector('.blob-viewer[data-type="rich"]', visible: false)

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
        visit_blob('files/lfs/file.md')

        wait_for_ajax
      end

      it 'displays the blob' do
        aggregate_failures do
          # shows text
          expect(page).to have_content('size 1575078')

          # does not show a viewer switcher
          expect(page).not_to have_selector('.js-blob-viewer-switcher')

          # shows an enabled copy button
          expect(page).to have_selector('.js-copy-blob-source-btn:not(.disabled)')

          # shows a raw button
          expect(page).to have_link('Open raw')
        end
      end
    end
  end

  context 'PDF file' do
    before do
      project.add_master(project.creator)

      Files::CreateService.new(
        project,
        project.creator,
        start_branch: 'master',
        branch_name: 'master',
        commit_message: "Add PDF",
        file_path: 'files/test.pdf',
        file_content: File.read(Rails.root.join('spec/javascripts/blob/pdf/test.pdf'))
      ).execute

      visit_blob('files/test.pdf')

      wait_for_ajax
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
        expect(page).to have_link('Download')
      end
    end
  end

  context 'ISO file (stored in LFS)' do
    context 'when LFS is enabled on the project' do
      before do
        allow(Gitlab.config.lfs).to receive(:enabled).and_return(true)
        project.update_attribute(:lfs_enabled, true)

        visit_blob('files/lfs/lfs_object.iso')

        wait_for_ajax
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
          expect(page).to have_link('Download')
        end
      end
    end

    context 'when LFS is disabled on the project' do
      before do
        visit_blob('files/lfs/lfs_object.iso')

        wait_for_ajax
>>>>>>> ce-com/master
      end
    end

    context 'visiting with a line number anchor' do
      before do
        visit_blob('files/markdown/ruby-style-guide.md', 'L1')

        wait_for_ajax
      end

      it 'displays the blob' do
        aggregate_failures do
          # hides the rich viewer
          expect(page).to have_selector('.blob-viewer[data-type="simple"]')
          expect(page).to have_selector('.blob-viewer[data-type="rich"]', visible: false)

          # highlights the line in question
          expect(page).to have_selector('#LC1.hll')

          # shows highlighted Markdown code
          expect(page).to have_content("[PEP-8](http://www.python.org/dev/peps/pep-0008/)")

          # shows an enabled copy button
          expect(page).to have_selector('.js-copy-blob-source-btn:not(.disabled)')
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

        visit_blob('files/lfs/file.md')

        wait_for_ajax
      end

      it 'displays an error' do
        aggregate_failures do
          # hides the simple viewer
          expect(page).to have_selector('.blob-viewer[data-type="simple"]', visible: false)
          expect(page).to have_selector('.blob-viewer[data-type="rich"]')

          # shows an error message
          expect(page).to have_content('The rendered file could not be displayed because it is stored in LFS. You can view the source or download it instead.')

          # shows a viewer switcher
          expect(page).to have_selector('.js-blob-viewer-switcher')

          # does not show a copy button
          expect(page).not_to have_selector('.js-copy-blob-source-btn')
        end
      end

      context 'switching to the simple viewer' do
        before do
          find('.js-blob-viewer-switcher .js-blob-viewer-switch-btn[data-viewer=simple]').click

          wait_for_ajax
        end

        it 'displays an error' do
          aggregate_failures do
            # hides the rich viewer
            expect(page).to have_selector('.blob-viewer[data-type="simple"]')
            expect(page).to have_selector('.blob-viewer[data-type="rich"]', visible: false)

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
        visit_blob('files/lfs/file.md')

        wait_for_ajax
      end

      it 'displays the blob' do
        aggregate_failures do
          # shows text
          expect(page).to have_content('size 1575078')

          # does not show a viewer switcher
          expect(page).not_to have_selector('.js-blob-viewer-switcher')

          # shows an enabled copy button
          expect(page).to have_selector('.js-copy-blob-source-btn:not(.disabled)')
        end
      end
    end
  end

  context 'PDF file' do
    before do
      project.add_master(project.creator)

      Files::CreateService.new(
        project,
        project.creator,
        start_branch: 'master',
        branch_name: 'master',
        commit_message: "Add PDF",
        file_path: 'files/test.pdf',
        file_content: File.read(Rails.root.join('spec/javascripts/blob/pdf/test.pdf'))
      ).execute

      visit_blob('files/test.pdf')

      wait_for_ajax
    end

    it 'displays the blob' do
      aggregate_failures do
        # shows rendered PDF
        expect(page).to have_selector('.js-pdf-viewer')

        # does not show a viewer switcher
        expect(page).not_to have_selector('.js-blob-viewer-switcher')

        # does not show a copy button
        expect(page).not_to have_selector('.js-copy-blob-source-btn')
      end
    end
  end

  context 'ISO file (stored in LFS)' do
    context 'when LFS is enabled on the project' do
      before do
        allow(Gitlab.config.lfs).to receive(:enabled).and_return(true)
        project.update_attribute(:lfs_enabled, true)

        visit_blob('files/lfs/lfs_object.iso')

        wait_for_ajax
      end

      it 'displays the blob' do
        aggregate_failures do
          # shows a download link
          expect(page).to have_link('Download (1.5 MB)')

          # does not show a viewer switcher
          expect(page).not_to have_selector('.js-blob-viewer-switcher')

          # does not show a copy button
          expect(page).not_to have_selector('.js-copy-blob-source-btn')
        end
      end
    end

    context 'when LFS is disabled on the project' do
      before do
        visit_blob('files/lfs/lfs_object.iso')

        wait_for_ajax
      end

      it 'displays the blob' do
        aggregate_failures do
          # shows text
          expect(page).to have_content('size 1575078')

          # does not show a viewer switcher
          expect(page).not_to have_selector('.js-blob-viewer-switcher')

          # shows an enabled copy button
          expect(page).to have_selector('.js-copy-blob-source-btn:not(.disabled)')
        end
      end
    end
  end

  context 'ZIP file' do
    before do
      visit_blob('Gemfile.zip')

      wait_for_ajax
    end

    it 'displays the blob' do
      aggregate_failures do
        # shows a download link
        expect(page).to have_link('Download (2.11 KB)')

        # does not show a viewer switcher
        expect(page).not_to have_selector('.js-blob-viewer-switcher')

<<<<<<< HEAD
        # does not show a copy button
        expect(page).not_to have_selector('.js-copy-blob-source-btn')
=======
      it 'displays the blob' do
        aggregate_failures do
          # shows text
          expect(page).to have_content('size 1575078')

          # does not show a viewer switcher
          expect(page).not_to have_selector('.js-blob-viewer-switcher')

          # shows an enabled copy button
          expect(page).to have_selector('.js-copy-blob-source-btn:not(.disabled)')

          # shows a raw button
          expect(page).to have_link('Open raw')
        end
      end
    end
  end

  context 'ZIP file' do
    before do
      visit_blob('Gemfile.zip')

      wait_for_ajax
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
        expect(page).to have_link('Download')
      end
    end
  end
end
