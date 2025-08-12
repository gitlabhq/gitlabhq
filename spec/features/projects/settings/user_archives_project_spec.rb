# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Projects > Settings > User archives a project', :js, feature_category: :groups_and_projects do
  let_it_be(:user) { create(:user) }

  let_it_be_with_reload(:group) { create(:group, owners: [user]) }
  let_it_be_with_reload(:project) { create(:project, group: group) }

  before do
    sign_in(user)
  end

  context 'when group is archived' do
    before do
      group.archive

      visit edit_project_path(project)
    end

    it 'cannot archive project' do
      expect(page).not_to have_button(s_('GroupProjectArchiveSettings|Archive'))
    end

    context 'when `archive_group` flag is disabled' do
      before do
        stub_feature_flags(archive_group: false)

        visit edit_project_path(project)
      end

      # This becomes a no-op as our policy prevents archiving projects that belongs to an archived group.
      # The current version is not built to handle this scenario.
      it 'cannot archive project' do
        expect(page).to have_content('Archive project')

        click_link('Archive')
        click_button('Archive project')

        expect(project.reload.archived?).to be(false)
      end
    end
  end

  context 'when group is not archived' do
    context 'when project is not archived' do
      before do
        visit edit_project_path(project)
      end

      it 'can archive project' do
        click_button s_('GroupProjectArchiveSettings|Archive')

        expect(page).to have_current_path(project_path(project))
        expect(page).to have_content('This is an archived project.')
      end

      context 'when `archive_group` flag is disabled' do
        before do
          stub_feature_flags(archive_group: false)

          visit edit_project_path(project)
        end

        it 'can archive project' do
          expect(page).to have_content('Archive project')

          click_link('Archive')
          click_button('Archive project')

          expect(page).to have_content('This is an archived project.')
        end
      end
    end

    context 'when project is archived' do
      before do
        project.update!(archived: true)

        visit edit_project_path(project)
      end

      it 'can unarchive project' do
        expect(page).to have_content('Unarchive project')

        click_link('Unarchive')

        expect(page).not_to have_content('This is an archived project.')
      end

      context 'when `archive_group` flag is disabled' do
        before do
          stub_feature_flags(archive_group: false)

          visit edit_project_path(project)
        end

        it 'can unarchive project' do
          expect(page).to have_content('Unarchive project')

          click_link('Unarchive')

          expect(page).not_to have_content('This is an archived project.')
        end
      end
    end
  end
end
