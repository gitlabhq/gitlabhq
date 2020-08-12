# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Commit diff', :js do
  include RepoHelpers

  let(:user)          { create(:user) }
  let(:project)       { create(:project, :public, :repository) }

  using RSpec::Parameterized::TableSyntax

  where(:view, :async_diff_file_loading) do
    'inline' | true
    'inline' | false
    'parallel' | true
    'parallel' | false
  end

  with_them do
    before do
      stub_feature_flags(async_commit_diff_files: async_diff_file_loading)
      project.add_maintainer(user)
      sign_in user
      visit project_commit_path(project, sample_commit.id, view: view)
    end

    it "adds comment to diff" do
      diff_line_num = first('.diff-line-num.new')

      diff_line_num.hover
      diff_line_num.find('.js-add-diff-note-button').click

      page.within(first('.diff-viewer')) do
        find('.js-note-text').set 'test comment'

        click_button 'Comment'

        expect(page).to have_content('test comment')
      end
    end
  end
end
