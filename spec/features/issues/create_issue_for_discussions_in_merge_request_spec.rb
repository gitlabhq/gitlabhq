# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Resolving all open threads in a merge request from an issue', :js, feature_category: :team_planning do
  let(:user) { create(:user) }
  let(:project) { create(:project, :repository) }
  let(:merge_request) { create(:merge_request, source_project: project) }
  let!(:discussion) { create(:diff_note_on_merge_request, noteable: merge_request, project: project).to_discussion }

  def resolve_all_discussions_link_selector(title: "")
    url = new_project_issue_path(project, merge_request_to_resolve_discussions_of: merge_request.iid, merge_request_id: merge_request.id)

    if title.empty?
      %(a[href="#{url}"])
    else
      %(a[title="#{title}"][href="#{url}"])
    end
  end

  describe 'as a user with access to the project' do
    before do
      project.add_maintainer(user)
      sign_in user
      visit project_merge_request_path(project, merge_request)
    end

    it 'shows a button to resolve all threads by creating a new issue' do
      within_testid('discussions-counter-text') do
        click_button 'Thread options'

        expect(page).to have_link(_("Resolve all with new issue"), href: new_project_issue_path(project, merge_request_to_resolve_discussions_of: merge_request.iid, merge_request_id: merge_request.id))
      end
    end

    context 'resolving the thread' do
      it 'hides the link for creating a new issue' do
        within_testid('reply-wrapper') do
          click_button 'Resolve thread'
        end

        expect(page).not_to have_selector resolve_all_discussions_link_selector
      end
    end

    context 'creating an issue for threads' do
      before do
        allow(Gitlab::QueryLimiting::Transaction).to receive(:threshold).and_return(200)
      end

      it 'creates an issue' do
        click_button 'Thread options'
        send_keys :down, :down, :enter # Select "Resolve all with new issue". For some reason, there's a glitch on CI which prevents us from clicking it normally

        expect(find_field('Title').value).to include(merge_request.title)
        expect(find_field('Description').value).to include(discussion.first_note.note)
        expect(page).to have_text("Creating this issue will resolve all threads in !#{merge_request.iid}")

        # Actually creates an issue for the project
        expect { click_button 'Create issue' }.to change { project.issues.reload.size }.by(1)

        # Resolves the discussion in the merge request
        discussion.first_note.reload
        expect(discussion.resolved?).to be(true)

        # Issue title includes MR title
        expect(page).to have_content(%(Follow-up from "#{merge_request.title}"))
      end
    end

    context 'for a project where all threads need to be resolved before merging' do
      before do
        project.update_attribute(:only_allow_merge_if_all_discussions_are_resolved, true)
      end

      context 'with the internal tracker disabled' do
        before do
          project.project_feature.update_attribute(:issues_access_level, ProjectFeature::DISABLED)
          visit project_merge_request_path(project, merge_request)
        end

        it 'does not show a link to create a new issue' do
          click_button 'Thread options'

          expect(page).not_to have_link 'Resolve all with new issue'
        end
      end

      context 'merge request has threads that need to be resolved' do
        before do
          visit project_merge_request_path(project, merge_request)
        end

        it 'shows a warning that the merge request contains unresolved threads' do
          click_button 'Expand merge checks'

          expect(page).to have_content 'Open threads must be resolved'
        end
      end
    end
  end

  describe 'as a reporter' do
    before do
      project.add_reporter(user)
      sign_in user
      visit project_merge_request_path(project, merge_request)
    end

    it 'does not allow reporter to resolve threads' do
      click_button 'Thread options'

      expect(page).not_to have_link 'Resolve all with new issue'
      expect(page).not_to have_button 'Resolve thread'
    end
  end
end
