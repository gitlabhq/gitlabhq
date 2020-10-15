# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Projects > Files > User browses LFS files' do
  let(:project) { create(:project, :repository) }
  let(:user) { project.owner }

  before do
    sign_in(user)
  end

  context 'when LFS is disabled', :js do
    before do
      allow_any_instance_of(Project).to receive(:lfs_enabled?).and_return(false)
      visit project_tree_path(project, 'lfs')
      wait_for_requests
    end

    it 'is possible to see raw content of LFS pointer' do
      click_link 'files'

      page.within('.repo-breadcrumb') do
        expect(page).to have_link('files')
      end

      click_link 'lfs'

      page.within('.repo-breadcrumb') do
        expect(page).to have_link('lfs')
      end

      click_link 'lfs_object.iso'

      expect(page).to have_content 'version https://git-lfs.github.com/spec/v1'
      expect(page).to have_content 'oid sha256:91eff75a492a3ed0dfcb544d7f31326bc4014c8551849c192fd1e48d4dd2c897'
      expect(page).to have_content 'size 1575078'
      expect(page).not_to have_content 'Download (1.5 MB)'
    end
  end

  context 'when LFS is enabled', :js do
    before do
      allow_any_instance_of(Project).to receive(:lfs_enabled?).and_return(true)
      visit project_tree_path(project, 'lfs')
      wait_for_requests
    end

    it 'shows an LFS object' do
      click_link('files')

      page.within('.repo-breadcrumb') do
        expect(page).to have_link('files')
      end

      click_link('lfs')
      click_link('lfs_object.iso')

      expect(page).to have_content('Download (1.5 MB)')
      expect(page).not_to have_content('version https://git-lfs.github.com/spec/v1')
      expect(page).not_to have_content('oid sha256:91eff75a492a3ed0dfcb544d7f31326bc4014c8551849c192fd1e48d4dd2c897')
      expect(page).not_to have_content('size 1575078')

      page.within('.content') do
        expect(page).to have_content('Delete')
        expect(page).to have_content('History')
        expect(page).to have_content('Permalink')
        expect(page).to have_content('Replace')
        expect(page).to have_link('Download')

        expect(page).not_to have_content('Annotate')
        expect(page).not_to have_content('Blame')

        expect(page).not_to have_selector(:link_or_button, text: /^Edit$/)
        expect(page).to have_selector(:link_or_button, 'Edit in Web IDE')
      end
    end

    context 'when feature flag :consolidated_edit_button is off' do
      before do
        stub_feature_flags(consolidated_edit_button: false)

        click_link('files')
        click_link('lfs')
        click_link('lfs_object.iso')
      end

      it 'does not show single file edit link' do
        page.within('.content') do
          expect(page).to have_selector(:link_or_button, 'Web IDE')
          expect(page).not_to have_selector(:link_or_button, 'Edit')
        end
      end
    end
  end
end
