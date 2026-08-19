# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Reportable note on commit', :js, feature_category: :source_code_management do
  include RepoHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :repository) }

  before_all do
    project.add_maintainer(user)
  end

  before do
    sign_in(user)
  end

  shared_examples 'a reportable note in Rapid Diffs' do
    let(:comment) { find("#note_#{note.id}", text: note.note) }

    def open_more_actions_dropdown
      click_button 'More actions'
      return if has_testid?('disclosure-content', wait: 2) # rubocop:disable RSpec/AvoidConditionalStatements -- retry click if dropdown didn't open

      click_button 'More actions'
    end

    it 'can be edited and deleted', :aggregate_failures do
      within(comment) do
        expect(page).to have_button('Edit comment')
        open_more_actions_dropdown

        within_testid('disclosure-content') do
          expect(page).to have_button('Delete comment')
        end
      end
    end

    it 'report button links to a report page', :aggregate_failures do
      within(comment) do
        open_more_actions_dropdown

        within_testid('disclosure-content') do
          find_by_testid('report-abuse-button').click
        end
      end

      choose "They're posting spam or unsolicited content."
      click_button 'Next'

      expect(find('#user_name')['value']).to match(note.author.username)
      expect(find('#abuse_report_category', visible: false)['value']).to match(/spam/i)
    end
  end

  context 'a normal note' do
    let!(:note) { create(:note_on_commit, commit_id: sample_commit.id, project: project) }

    before do
      visit project_commit_path(project, sample_commit.id)
      find("#note_#{note.id}", text: note.note)
    end

    it_behaves_like 'a reportable note in Rapid Diffs'
  end

  context 'a diff note' do
    let!(:note) { create(:diff_note_on_commit, commit_id: sample_commit.id, project: project) }

    before do
      visit project_commit_path(project, sample_commit.id)
      find("#note_#{note.id}", text: note.note)
    end

    it_behaves_like 'a reportable note in Rapid Diffs'
  end
end
