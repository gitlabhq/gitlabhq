# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Diff file viewer', :js, :with_clean_rails_cache, feature_category: :code_review_workflow do
  let(:project) { create(:project, :public, :repository) }

  def visit_commit(sha, anchor: nil)
    visit project_commit_path(project, sha, anchor: anchor)

    wait_for_requests
  end

  context 'Ruby file' do
    before do
      visit_commit('570e7b2abdd848b95f2f578043fc23bd6f6fd24d')
    end

    it 'shows highlighted Ruby code' do
      within('.diff-file[id="2f6fcd96b88b36ce98c38da085c795a27d92a3dd"]') do
        expect(page).to have_css(".js-syntax-highlight")
        expect(page).to have_content("def popen(cmd, path=nil)")
      end
    end
  end

  context 'Ruby file (stored in LFS)' do
    before do
      project.add_maintainer(project.creator)

      @commit_id = Files::CreateService.new(
        project,
        project.creator,
        start_branch: 'master',
        branch_name: 'master',
        commit_message: "Add Ruby file in LFS",
        file_path: 'files/lfs/ruby.rb',
        file_content: project.repository.blob_at('master', 'files/lfs/lfs_object.iso').data
      ).execute[:result]
    end

    context 'when LFS is enabled on the project' do
      before do
        allow(Gitlab.config.lfs).to receive(:enabled).and_return(true)
        project.update_attribute(:lfs_enabled, true)

        visit_commit(@commit_id)
      end

      it 'shows an error message' do
        expect(page).to have_content('Source diff could not be displayed: it is stored in LFS. Options to address this: view the blob.')
      end
    end

    context 'when LFS is disabled on the project' do
      before do
        visit_commit(@commit_id)
      end

      it 'displays the diff' do
        expect(page).to have_content('size 1575078')
      end
    end
  end

  context 'Image file' do
    context 'Replaced' do
      before do
        visit_commit('2f63565e7aac07bcdadb654e253078b727143ec4')
      end

      it 'shows a rendered image' do
        within('.diff-file[id="e986451b8f7397b617dbb6fffcb5539328c56921"]') do
          expect(page).to have_css('img[alt="files/images/6049019_460s.jpg"]')
        end
      end

      it 'shows view replaced and view file links' do
        expect(page.all('.file-actions a').length).to eq 2
        expect(page.all('.file-actions a')[0]).to have_content 'View replaced file @'
        expect(page.all('.file-actions a')[1]).to have_content 'View file @'
      end
    end

    context 'Added' do
      before do
        visit_commit('33f3729a45c02fc67d00adb1b8bca394b0e761d9')
      end

      it 'shows view file link' do
        expect(page.all('.file-actions a').length).to eq 1
        expect(page.all('.file-actions a')[0]).to have_content 'View file @'
      end
    end

    context 'Deleted' do
      before do
        visit_commit('7fd7a459706ee87be6f855fd98ce8c552b15529a')
      end

      it 'shows view file link' do
        expect(page.all('.file-actions a').length).to eq 1
        expect(page.all('.file-actions a')[0]).to have_content 'View file @'
      end
    end
  end

  context 'ISO file (stored in LFS)' do
    context 'when LFS is enabled on the project' do
      before do
        allow(Gitlab.config.lfs).to receive(:enabled).and_return(true)
        project.update_attribute(:lfs_enabled, true)

        visit_commit('048721d90c449b244b7b4c53a9186b04330174ec')
      end

      it 'shows that file was added' do
        expect(page).to have_content('File added')
      end
    end

    context 'when LFS is disabled on the project' do
      before do
        visit_commit('048721d90c449b244b7b4c53a9186b04330174ec')
      end

      it 'displays the diff' do
        expect(page).to have_content('size 1575078')
      end
    end
  end

  context 'ZIP file' do
    before do
      visit_commit('ae73cb07c9eeaf35924a10f713b364d32b2dd34f')
    end

    it 'shows that file was added' do
      expect(page).to have_content('File added')
    end
  end

  context 'renamed file' do
    before do
      visit_commit('6907208d755b60ebeacb2e9dfea74c92c3449a1f')
    end

    it 'shows the filename with diff highlight' do
      within('.file-header-content') do
        expect(page).to have_css('.idiff.left.right.deletion')
        expect(page).to have_content('files/js/commit.coffee')
      end
    end
  end

  context 'binary file that appears to be text in the first 1024 bytes' do
    before do
      visit_commit('7b1cf4336b528e0f3d1d140ee50cafdbc703597c')
    end

    it 'shows the diff is collapsed' do
      expect(page).to have_content('This diff is collapsed. Click to expand it.')
    end

    context 'expanding the diff' do
      before do
        click_button 'Click to expand it.'

        wait_for_requests
      end

      it 'shows that file was added' do
        expect(page).to have_content('File added')
      end
    end
  end

  context 'when the the encoding of the file is unsupported' do
    before do
      visit_commit('f05a98786e4274708e1fa118c7ad3a29d1d1b9a3')
    end

    it 'shows it is not diffable' do
      expect(page).to have_content("File suppressed by a .gitattributes entry, the file's encoding is unsupported, or the file size exceeds the limit.")
    end
  end
end
