# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Projects > Settings > User archives a project', :js, feature_category: :groups_and_projects do
  include SafeFormatHelper
  include ActionView::Helpers::TagHelper

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

    it 'cannot archive/unarchive project', :aggregate_failures do
      expect(page).not_to have_button(s_('GroupProjectArchiveSettings|Archive'))
      expect(page).not_to have_button(s_('GroupProjectUnarchiveSettings|Unarchive'))
    end
  end

  context 'when group is not archived' do
    context 'when project is not archived' do
      before do
        visit edit_project_path(project)
      end

      it 'can archive project', :aggregate_failures do
        click_button s_('GroupProjectArchiveSettings|Archive')

        expect(page).to have_current_path(project_path(project))
        expect(page.body).to include(safe_format(
          _('This project is archived. Its data is %{strong_open}read-only%{strong_close}.'),
          tag_pair(tag.strong, :strong_open, :strong_close)
        ))
      end
    end

    context 'when project is archived' do
      before do
        project.update!(archived: true)

        visit edit_project_path(project)
      end

      it 'can unarchive project', :aggregate_failures do
        expect(page).to have_content('Unarchive project')

        click_button s_('GroupProjectUnarchiveSettings|Unarchive')

        expect(page).to have_current_path(project_path(project))
        expect(page.body).not_to include(safe_format(
          _('This project is archived. Its data is %{strong_open}read-only%{strong_close}.'),
          tag_pair(tag.strong, :strong_open, :strong_close)
        ))
      end
    end
  end
end
