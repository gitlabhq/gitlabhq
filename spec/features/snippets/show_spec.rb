require 'spec_helper'

feature 'Snippet', :js do
  let(:project) { create(:project, :repository) }
  let(:snippet) { create(:personal_snippet, :public, file_name: file_name, content: content) }

  context 'Ruby file' do
    let(:file_name) { 'popen.rb' }
    let(:content) { project.repository.blob_at('master', 'files/ruby/popen.rb').data }

    before do
      visit snippet_path(snippet)

      wait_for_requests
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

        # shows a download button
        expect(page).to have_link('Download')
      end
    end
  end

  context 'Markdown file' do
    let(:file_name) { 'ruby-style-guide.md' }
    let(:content) { project.repository.blob_at('master', 'files/markdown/ruby-style-guide.md').data }

    context 'visiting directly' do
      before do
        visit snippet_path(snippet)

        wait_for_requests
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

          # shows a download button
          expect(page).to have_link('Download')
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

            wait_for_requests
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
        visit snippet_path(snippet, anchor: 'L1')

        wait_for_requests
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
end
