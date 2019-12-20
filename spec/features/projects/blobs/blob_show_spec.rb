# frozen_string_literal: true

require 'spec_helper'

describe 'File blob', :js do
  include MobileHelpers

  let(:project) { create(:project, :public, :repository) }

  def visit_blob(path, anchor: nil, ref: 'master')
    visit project_blob_path(project, File.join(ref, path), anchor: anchor)

    wait_for_requests
  end

  context 'Ruby file' do
    before do
      visit_blob('files/ruby/popen.rb')

      wait_for_requests
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
        expect(page).to have_link('Open raw')
      end
    end

    it 'displays file actions on all screen sizes' do
      file_actions_selector = '.file-actions'

      resize_screen_sm
      expect(page).to have_selector(file_actions_selector, visible: true)

      resize_screen_xs
      expect(page).to have_selector(file_actions_selector, visible: true)
    end
  end

  context 'Markdown file' do
    context 'visiting directly' do
      before do
        visit_blob('files/markdown/ruby-style-guide.md')

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
        visit_blob('files/markdown/ruby-style-guide.md', anchor: 'L1')
      end

      it 'displays the blob using the simple viewer' do
        aggregate_failures do
          # hides the rich viewer
          expect(page).to have_selector('.blob-viewer[data-type="simple"]')
          expect(page).to have_selector('.blob-viewer[data-type="rich"]', visible: false)

          # highlights the line in question
          expect(page).to have_selector('#LC1.hll')

          # shows highlighted Markdown code
          expect(page).to have_css(".js-syntax-highlight")
          expect(page).to have_content("[PEP-8](http://www.python.org/dev/peps/pep-0008/)")

          # shows an enabled copy button
          expect(page).to have_selector('.js-copy-blob-source-btn:not(.disabled)')
        end
      end
    end
  end

  context 'Markdown rendering' do
    before do
      project.add_maintainer(project.creator)

      Files::CreateService.new(
        project,
        project.creator,
        start_branch: 'master',
        branch_name: 'master',
        commit_message: "Add RedCarpet and CommonMark Markdown ",
        file_path: 'files/commonmark/file.md',
        file_content: "1. one\n  - sublist\n"
      ).execute
    end

    context 'when rendering default markdown' do
      before do
        visit_blob('files/commonmark/file.md')

        wait_for_requests
      end

      it 'renders using CommonMark' do
        aggregate_failures do
          expect(page).to have_content("sublist")
          expect(page).not_to have_xpath("//ol//li//ul")
        end
      end
    end
  end

  context 'Markdown file (stored in LFS)' do
    before do
      project.add_maintainer(project.creator)

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

        wait_for_requests
      end

      it 'displays an error' do
        aggregate_failures do
          # hides the simple viewer
          expect(page).to have_selector('.blob-viewer[data-type="simple"]', visible: false)
          expect(page).to have_selector('.blob-viewer[data-type="rich"]')

          # shows an error message
          expect(page).to have_content('The rendered file could not be displayed because it is stored in LFS. You can download it instead.')

          # shows a viewer switcher
          expect(page).to have_selector('.js-blob-viewer-switcher')

          # does not show a copy button
          expect(page).not_to have_selector('.js-copy-blob-source-btn')

          # shows a download button
          expect(page).to have_link('Download')
        end
      end

      context 'switching to the simple viewer' do
        before do
          find('.js-blob-viewer-switcher .js-blob-viewer-switch-btn[data-viewer=simple]').click

          wait_for_requests
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

        wait_for_requests
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
      project.add_maintainer(project.creator)

      Files::CreateService.new(
        project,
        project.creator,
        start_branch: 'master',
        branch_name: 'master',
        commit_message: "Add PDF",
        file_path: 'files/test.pdf',
        file_content: project.repository.blob_at('add-pdf-file', 'files/pdf/test.pdf').data
      ).execute

      visit_blob('files/test.pdf')

      wait_for_requests
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

        wait_for_requests
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

        wait_for_requests
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

  context 'ZIP file' do
    before do
      visit_blob('Gemfile.zip')

      wait_for_requests
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

  context 'empty file' do
    before do
      project.add_maintainer(project.creator)

      Files::CreateService.new(
        project,
        project.creator,
        start_branch: 'master',
        branch_name: 'master',
        commit_message: "Add empty file",
        file_path: 'files/empty.md',
        file_content: ''
      ).execute

      visit_blob('files/empty.md')

      wait_for_requests
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
        expect(page).not_to have_link('Download')
        expect(page).not_to have_link('Open raw')
      end
    end
  end

  context 'binary file that appears to be text in the first 1024 bytes' do
    before do
      visit_blob('encoding/binary-1.bin', ref: 'binary-encoding')
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
        expect(page).to have_link('Open raw')
      end
    end
  end

  context '.gitlab-ci.yml' do
    before do
      project.add_maintainer(project.creator)

      Files::CreateService.new(
        project,
        project.creator,
        start_branch: 'master',
        branch_name: 'master',
        commit_message: "Add .gitlab-ci.yml",
        file_path: '.gitlab-ci.yml',
        file_content: File.read(Rails.root.join('spec/support/gitlab_stubs/gitlab_ci.yml'))
      ).execute

      visit_blob('.gitlab-ci.yml')
    end

    it 'displays an auxiliary viewer' do
      aggregate_failures do
        # shows that configuration is valid
        expect(page).to have_content('This GitLab CI configuration is valid.')

        # shows a learn more link
        expect(page).to have_link('Learn more')
      end
    end
  end

  context '.gitlab/route-map.yml' do
    before do
      project.add_maintainer(project.creator)

      Files::CreateService.new(
        project,
        project.creator,
        start_branch: 'master',
        branch_name: 'master',
        commit_message: "Add .gitlab/route-map.yml",
        file_path: '.gitlab/route-map.yml',
        file_content: <<-MAP.strip_heredoc
          # Team data
          - source: 'data/team.yml'
            public: 'team/'
        MAP
      ).execute

      visit_blob('.gitlab/route-map.yml')
    end

    it 'displays an auxiliary viewer' do
      aggregate_failures do
        # shows that map is valid
        expect(page).to have_content('This Route Map is valid.')

        # shows a learn more link
        expect(page).to have_link('Learn more')
      end
    end
  end

  context 'LICENSE' do
    before do
      visit_blob('LICENSE')
    end

    it 'displays an auxiliary viewer' do
      aggregate_failures do
        # shows license
        expect(page).to have_content('This project is licensed under the MIT License.')

        # shows a learn more link
        expect(page).to have_link('Learn more', href: 'http://choosealicense.com/licenses/mit/')
      end
    end
  end

  context '*.gemspec' do
    before do
      project.add_maintainer(project.creator)

      Files::CreateService.new(
        project,
        project.creator,
        start_branch: 'master',
        branch_name: 'master',
        commit_message: "Add activerecord.gemspec",
        file_path: 'activerecord.gemspec',
        file_content: <<-SPEC.strip_heredoc
          Gem::Specification.new do |s|
            s.platform    = Gem::Platform::RUBY
            s.name        = "activerecord"
          end
        SPEC
      ).execute

      visit_blob('activerecord.gemspec')
    end

    it 'displays an auxiliary viewer' do
      aggregate_failures do
        # shows names of dependency manager and package
        expect(page).to have_content('This project manages its dependencies using RubyGems.')

        # shows a learn more link
        expect(page).to have_link('Learn more', href: 'https://rubygems.org/')
      end
    end
  end

  context 'realtime pipelines' do
    before do
      Files::CreateService.new(
        project,
        project.creator,
        start_branch: 'feature',
        branch_name: 'feature',
        commit_message: "Add ruby file",
        file_path: 'files/ruby/test.rb',
        file_content: "# Awesome content"
      ).execute

      create(:ci_pipeline, status: 'running', project: project, ref: 'feature', sha: project.commit('feature').sha)
      visit_blob('files/ruby/test.rb', ref: 'feature')
    end

    it 'shows the realtime pipeline status' do
      page.within('.commit-actions') do
        expect(page).to have_css('.ci-status-icon')
        expect(page).to have_css('.ci-status-icon-running')
        expect(page).to have_css('.js-ci-status-icon-running')
      end
    end
  end

  context 'for subgroups' do
    let(:group) { create(:group) }
    let(:subgroup) { create(:group, parent: group) }
    let(:project) { create(:project, :public, :repository, group: subgroup) }

    it 'renders tree table without errors' do
      visit_blob('README.md')

      expect(page).to have_selector('.file-content')
      expect(page).not_to have_selector('.flash-alert')
    end

    it 'displays a GPG badge' do
      visit_blob('CONTRIBUTING.md', ref: '33f3729a45c02fc67d00adb1b8bca394b0e761d9')

      expect(page).not_to have_selector '.gpg-status-box.js-loading-gpg-badge'
      expect(page).to have_selector '.gpg-status-box.invalid'
    end
  end

  context 'on signed merge commit' do
    it 'displays a GPG badge' do
      visit_blob('conflicting-file.md', ref: '6101e87e575de14b38b4e1ce180519a813671e10')

      expect(page).not_to have_selector '.gpg-status-box.js-loading-gpg-badge'
      expect(page).to have_selector '.gpg-status-box.invalid'
    end
  end

  context 'when static objects external storage is enabled' do
    before do
      stub_application_setting(static_objects_external_storage_url: 'https://cdn.gitlab.com')
    end

    context 'private project' do
      let_it_be(:project) { create(:project, :repository, :private) }
      let_it_be(:user) { create(:user) }

      before do
        project.add_developer(user)

        sign_in(user)
        visit_blob('README.md')
      end

      it 'shows open raw and download buttons with external storage URL prepended and user token appended to their href' do
        path = project_raw_path(project, 'master/README.md')
        raw_uri = "https://cdn.gitlab.com#{path}?token=#{user.static_object_token}"
        download_uri = "https://cdn.gitlab.com#{path}?inline=false&token=#{user.static_object_token}"

        aggregate_failures do
          expect(page).to have_link 'Open raw', href: raw_uri
          expect(page).to have_link 'Download', href: download_uri
        end
      end
    end

    context 'public project' do
      before do
        visit_blob('README.md')
      end

      it 'shows open raw and download buttons with external storage URL prepended to their href' do
        path = project_raw_path(project, 'master/README.md')
        raw_uri = "https://cdn.gitlab.com#{path}"
        download_uri = "https://cdn.gitlab.com#{path}?inline=false"

        aggregate_failures do
          expect(page).to have_link 'Open raw', href: raw_uri
          expect(page).to have_link 'Download', href: download_uri
        end
      end
    end
  end
end
