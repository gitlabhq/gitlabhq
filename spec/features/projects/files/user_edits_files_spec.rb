# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Projects > Files > User edits files', :js do
  include ProjectForksHelper
  include BlobSpecHelpers

  let(:project) { create(:project, :repository, name: 'Shop') }
  let(:project2) { create(:project, :repository, name: 'Another Project', path: 'another-project') }
  let(:project_tree_path_root_ref) { project_tree_path(project, project.repository.root_ref) }
  let(:project2_tree_path_root_ref) { project_tree_path(project2, project2.repository.root_ref) }
  let(:user) { create(:user) }

  before do
    sign_in(user)
  end

  after do
    unset_default_button
  end

  shared_examples 'unavailable for an archived project' do
    it 'does not show the edit link for an archived project', :js do
      project.update!(archived: true)
      visit project_tree_path(project, project.repository.root_ref)

      click_link('.gitignore')

      aggregate_failures 'available edit buttons' do
        expect(page).not_to have_text('Edit')
        expect(page).not_to have_text('Web IDE')

        expect(page).not_to have_text('Replace')
        expect(page).not_to have_text('Delete')
      end
    end
  end

  context 'when an user has write access', :js do
    before do
      project.add_maintainer(user)
      visit(project_tree_path_root_ref)
      wait_for_requests
    end

    it 'inserts a content of a file' do
      set_default_button('edit')
      click_link('.gitignore')
      click_link_or_button('Edit')
      find('.file-editor', match: :first)

      find('#editor')
      set_editor_value('*.rbca')

      expect(editor_value).to eq('*.rbca')
    end

    it 'does not show the edit link if a file is binary' do
      binary_file = File.join(project.repository.root_ref, 'files/images/logo-black.png')
      visit(project_blob_path(project, binary_file))
      wait_for_requests

      page.within '.content' do
        expect(page).not_to have_link('edit')
      end
    end

    it 'commits an edited file' do
      set_default_button('edit')
      click_link('.gitignore')
      click_link_or_button('Edit')
      find('.file-editor', match: :first)

      find('#editor')
      set_editor_value('*.rbca')
      fill_in(:commit_message, with: 'New commit message', visible: true)
      click_button('Commit changes')

      expect(current_path).to eq(project_blob_path(project, 'master/.gitignore'))

      wait_for_requests

      expect(page).to have_content('*.rbca')
    end

    it 'commits an edited file to a new branch' do
      set_default_button('edit')
      click_link('.gitignore')
      click_link_or_button('Edit')

      find('.file-editor', match: :first)

      find('#editor')
      set_editor_value('*.rbca')
      fill_in(:commit_message, with: 'New commit message', visible: true)
      fill_in(:branch_name, with: 'new_branch_name', visible: true)
      click_button('Commit changes')

      expect(current_path).to eq(project_new_merge_request_path(project))

      click_link('Changes')

      expect(page).to have_content('*.rbca')
    end

    it 'shows the diff of an edited file' do
      set_default_button('edit')
      click_link('.gitignore')
      click_link_or_button('Edit')
      find('.file-editor', match: :first)

      find('#editor')
      set_editor_value('*.rbca')
      click_link('Preview changes')

      expect(page).to have_css('.line_holder.new')
    end

    it_behaves_like 'unavailable for an archived project'
  end

  context 'when an user does not have write access', :js do
    before do
      project2.add_reporter(user)
      visit(project2_tree_path_root_ref)
      wait_for_requests
    end

    def expect_fork_prompt
      expect(page).to have_selector(:link_or_button, 'Fork')
      expect(page).to have_selector(:link_or_button, 'Cancel')
      expect(page).to have_content(
        "You can’t edit files directly in this project. "\
        "Fork this project and submit a merge request with your changes."
      )
    end

    def expect_fork_status
      expect(page).to have_content(
        "You're not allowed to make changes to this project directly. "\
        "A fork of this project has been created that you can make changes in, so you can submit a merge request."
      )
    end

    it 'inserts a content of a file in a forked project', :sidekiq_might_not_need_inline do
      set_default_button('edit')
      click_link('.gitignore')
      click_link_or_button('Edit')

      expect_fork_prompt

      click_link_or_button('Fork project')

      expect_fork_status

      find('.file-editor', match: :first)

      find('#editor')
      set_editor_value('*.rbca')

      expect(editor_value).to eq('*.rbca')
    end

    it 'opens the Web IDE in a forked project', :sidekiq_might_not_need_inline do
      set_default_button('webide')
      click_link('.gitignore')
      click_link_or_button('Web IDE')

      expect_fork_prompt

      click_link_or_button('Fork project')

      expect_fork_status

      expect(page).to have_css('.ide-sidebar-project-title', text: "#{project2.name} #{user.namespace.full_path}/#{project2.path}")
      expect(page).to have_css('.ide .multi-file-tab', text: '.gitignore')
    end

    it 'commits an edited file in a forked project', :sidekiq_might_not_need_inline do
      set_default_button('edit')
      click_link('.gitignore')
      click_link_or_button('Edit')

      expect_fork_prompt
      click_link_or_button('Fork project')

      find('.file-editor', match: :first)

      find('#editor')
      set_editor_value('*.rbca')
      fill_in(:commit_message, with: 'New commit message', visible: true)
      click_button('Commit changes')

      fork = user.fork_of(project2.reload)

      expect(current_path).to eq(project_new_merge_request_path(fork))

      wait_for_requests

      expect(page).to have_content('New commit message')
    end

    context 'when the user already had a fork of the project', :js do
      let!(:forked_project) { fork_project(project2, user, namespace: user.namespace, repository: true) }

      before do
        visit(project2_tree_path_root_ref)
        wait_for_requests
      end

      it 'links to the forked project for editing', :sidekiq_might_not_need_inline do
        set_default_button('edit')
        click_link('.gitignore')
        click_link_or_button('Edit')

        expect(page).not_to have_link('Fork project')

        find('#editor')
        set_editor_value('*.rbca')
        fill_in(:commit_message, with: 'Another commit', visible: true)
        click_button('Commit changes')

        fork = user.fork_of(project2)

        expect(current_path).to eq(project_new_merge_request_path(fork))

        wait_for_requests

        expect(page).to have_content('Another commit')
        expect(page).to have_content("From #{forked_project.full_path}")
        expect(page).to have_content("into #{project2.full_path}")
      end

      it_behaves_like 'unavailable for an archived project' do
        let(:project) { project2 }
      end
    end

    context 'when feature flag :consolidated_edit_button is off' do
      before do
        stub_feature_flags(consolidated_edit_button: false)
      end

      context 'when an user does not have write access', :js do
        before do
          project2.add_reporter(user)
          visit(project2_tree_path_root_ref)
          wait_for_requests
        end

        it 'inserts a content of a file in a forked project', :sidekiq_might_not_need_inline do
          set_default_button('edit')
          click_link('.gitignore')
          click_link_or_button('Edit')

          expect_fork_prompt

          click_link_or_button('Fork')

          expect_fork_status

          find('.file-editor', match: :first)

          find('#editor')
          set_editor_value('*.rbca')

          expect(editor_value).to eq('*.rbca')
        end

        it 'opens the Web IDE in a forked project', :sidekiq_might_not_need_inline do
          set_default_button('webide')
          click_link('.gitignore')
          click_link_or_button('Web IDE')

          expect_fork_prompt

          click_link_or_button('Fork')

          expect_fork_status

          expect(page).to have_css('.ide-sidebar-project-title', text: "#{project2.name} #{user.namespace.full_path}/#{project2.path}")
          expect(page).to have_css('.ide .multi-file-tab', text: '.gitignore')
        end

        it 'commits an edited file in a forked project', :sidekiq_might_not_need_inline do
          set_default_button('edit')
          click_link('.gitignore')
          click_link_or_button('Edit')

          expect_fork_prompt

          click_link_or_button('Fork')

          expect_fork_status

          find('.file-editor', match: :first)

          find('#editor')
          set_editor_value('*.rbca')
          fill_in(:commit_message, with: 'New commit message', visible: true)
          click_button('Commit changes')

          fork = user.fork_of(project2.reload)

          expect(current_path).to eq(project_new_merge_request_path(fork))

          wait_for_requests

          expect(page).to have_content('New commit message')
        end

        context 'when the user already had a fork of the project', :js do
          let!(:forked_project) { fork_project(project2, user, namespace: user.namespace, repository: true) }

          before do
            visit(project2_tree_path_root_ref)
            wait_for_requests
          end

          it 'links to the forked project for editing', :sidekiq_might_not_need_inline do
            set_default_button('edit')
            click_link('.gitignore')
            click_link_or_button('Edit')

            expect(page).not_to have_link('Fork')

            find('#editor')
            set_editor_value('*.rbca')
            fill_in(:commit_message, with: 'Another commit', visible: true)
            click_button('Commit changes')

            fork = user.fork_of(project2)

            expect(current_path).to eq(project_new_merge_request_path(fork))

            wait_for_requests

            expect(page).to have_content('Another commit')
            expect(page).to have_content("From #{forked_project.full_path}")
            expect(page).to have_content("into #{project2.full_path}")
          end

          it_behaves_like 'unavailable for an archived project' do
            let(:project) { project2 }
          end
        end
      end
    end
  end
end
