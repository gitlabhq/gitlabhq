# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User sees user popover', :js, feature_category: :groups_and_projects do
  include Features::NotesHelpers

  let_it_be(:user) { create(:user, pronouns: 'they/them') }
  let_it_be(:project) { create(:project, :repository, creator: user) }

  let(:merge_request) do
    create(:merge_request, source_project: project, target_project: project)
  end

  before do
    project.add_maintainer(user)
    sign_in(user)
  end

  subject { page }

  describe 'hovering over a user link in a merge request' do
    let(:popover_selector) { '[data-testid="user-popover"]' }

    before do
      visit project_merge_request_path(project, merge_request)
    end

    it 'displays user popover' do
      find('.detail-page-description .js-user-link').hover

      expect(page).to have_css(popover_selector, visible: true)

      page.within(popover_selector) do
        expect(page).to have_content("#{user.name} (they/them)")
      end
    end

    it 'displays user popover in system note', :sidekiq_inline do
      add_note("/assign @#{user.username}")

      find('.system-note-message .js-user-link').hover

      page.within(popover_selector) do
        expect(page).to have_content(user.name)
      end
    end
  end
end
