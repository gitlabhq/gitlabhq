# frozen_string_literal: true

require 'spec_helper'

describe 'User sees user popover', :js do
  include Spec::Support::Helpers::Features::NotesHelpers

  let_it_be(:project) { create(:project, :repository) }
  let(:user) { project.creator }
  let(:merge_request) do
    create(:merge_request, source_project: project, target_project: project)
  end

  before do
    project.add_maintainer(user)
    sign_in(user)
  end

  subject { page }

  describe 'hovering over a user link in a merge request' do
    let(:popover_selector) { '.user-popover' }

    before do
      visit project_merge_request_path(project, merge_request)
    end

    it 'displays user popover' do
      find('.js-user-link').hover

      expect(page).to have_css(popover_selector, visible: true)

      page.within(popover_selector) do
        expect(page).to have_content(user.name)
      end
    end

    it "displays user popover in system note" do
      add_note("/assign @#{user.username}")

      wait_for_requests

      find('.system-note-message .js-user-link').hover

      page.within(popover_selector) do
        expect(page).to have_content(user.name)
      end
    end
  end
end
