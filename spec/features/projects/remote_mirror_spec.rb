# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Project remote mirror', :feature, feature_category: :groups_and_projects do
  let(:project) { create(:project, :repository, :remote_mirror) }
  let(:remote_mirror) { project.remote_mirrors.first }
  let(:user) { create(:user) }

  describe 'On a project', :js do
    before do
      project.add_maintainer(user)
      sign_in user
    end

    context 'when last_error is present but last_update_at is not' do
      it 'renders error message without timstamp' do
        remote_mirror.update!(last_error: 'Some new error', last_update_at: nil)

        visit project_mirror_path(project)

        expect_mirror_to_have_error_and_timeago('Never')
      end
    end

    context 'when last_error and last_update_at are present' do
      it 'renders error message with timestamp' do
        remote_mirror.update!(last_error: 'Some new error', last_update_at: Time.zone.now - 5.minutes)

        visit project_mirror_path(project)

        expect_mirror_to_have_error_and_timeago('5 minutes ago')
      end
    end

    def expect_mirror_to_have_error_and_timeago(timeago)
      row = first('.js-mirrors-table-body tr')
      expect(row).to have_content('Error')
      expect(row).to have_content(timeago)
    end
  end
end
