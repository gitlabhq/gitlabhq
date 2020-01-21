# frozen_string_literal: true

require 'spec_helper'

describe 'Merge request > User toggles whitespace changes', :js do
  let(:merge_request) { create(:merge_request) }
  let(:project) { merge_request.project }
  let(:user) { project.creator }

  before do
    project.add_maintainer(user)
    sign_in(user)
    visit diffs_project_merge_request_path(project, merge_request)

    find('.js-show-diff-settings').click
  end

  it 'has a button to toggle whitespace changes' do
    expect(page).to have_content 'Show whitespace changes'
  end

  describe 'clicking "Hide whitespace changes" button' do
    it 'toggles the "Hide whitespace changes" button' do
      find('#show-whitespace').click

      visit diffs_project_merge_request_path(project, merge_request)

      find('.js-show-diff-settings').click

      expect(find('#show-whitespace')).to be_checked
    end
  end
end
