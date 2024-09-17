# frozen_string_literal: true

require 'spec_helper'
RSpec.describe 'Merge request > User sees discussions navigation', :js, feature_category: :code_review_workflow do
  let_it_be(:project) { create(:project, :public, :repository) }
  let_it_be(:user) { project.creator }
  let_it_be(:merge_request) { create(:merge_request, source_project: project) }

  before do
    project.add_maintainer(user)
    sign_in(user)
  end

  describe 'Code discussions' do
    let!(:position) do
      build(
        :text_diff_position, :added,
        file: "files/images/wm.svg",
        new_line: 1,
        diff_refs: merge_request.diff_refs
      )
    end

    let!(:first_discussion) do
      create(
        :diff_note_on_merge_request,
        noteable: merge_request,
        project: project,
        position: position
      ).to_discussion
    end

    let!(:second_discussion) do
      create(
        :diff_note_on_merge_request,
        noteable: merge_request,
        project: project,
        position: position
      ).to_discussion
    end

    let(:first_discussion_selector) { ".discussion[data-discussion-id='#{first_discussion.id}']" }
    let(:second_discussion_selector) { ".discussion[data-discussion-id='#{second_discussion.id}']" }

    shared_examples 'a page with a thread navigation' do
      context 'with active threads' do
        it 'navigates to the first thread' do
          goto_next_thread
          expect(page).to have_selector(first_discussion_selector, obscured: false)
        end

        it 'navigates to the last thread' do
          goto_previous_thread
          expect(page).to have_selector(second_discussion_selector, obscured: false)
        end

        it 'navigates through active threads' do
          goto_next_thread
          goto_next_thread
          expect(page).to have_selector(second_discussion_selector, obscured: false)
        end

        it 'cycles back to the first thread' do
          goto_next_thread
          goto_next_thread
          goto_next_thread
          expect(page).to have_selector(first_discussion_selector, obscured: false)
        end

        it 'cycles back to the last thread' do
          goto_previous_thread
          goto_previous_thread
          goto_previous_thread
          expect(page).to have_selector(second_discussion_selector, obscured: false)
        end
      end

      context 'with resolved threads' do
        let!(:resolved_discussion) do
          create(
            :diff_note_on_merge_request,
            noteable: merge_request,
            project: project,
            position: position
          ).to_discussion
        end

        let(:resolved_discussion_selector) { ".discussion[data-discussion-id='#{resolved_discussion.id}']" }

        before do
          # :resolved attr doesn't actually resolve the thread but just collapses it
          page.within(resolved_discussion_selector) do
            click_button text: 'Resolve thread'
          end
          page.execute_script("window.scrollTo(0,0)")
        end

        it 'excludes resolved threads during navigation',
          quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/383687' do
          goto_next_thread
          goto_next_thread
          goto_next_thread
          expect(page).to have_selector(first_discussion_selector, obscured: false)
        end
      end
    end

    describe "Overview page discussions navigation" do
      before do
        visit project_merge_request_path(project, merge_request)
      end

      it_behaves_like 'a page with a thread navigation'

      context 'with collapsed threads' do
        before do
          page.within(first_discussion_selector) do
            click_button text: 'Collapse replies'
          end
        end

        it 'expands threads during navigation' do
          goto_next_thread
          expect(page).to have_selector "#note_#{first_discussion.first_note.id}"
        end
      end
    end

    describe "Changes page discussions navigation" do
      before do
        visit diffs_project_merge_request_path(project, merge_request)
      end

      it_behaves_like 'a page with a thread navigation'
    end
  end

  describe 'Merge request discussions' do
    let_it_be(:first_discussion) do
      create(:discussion_note_on_merge_request, noteable: merge_request, project: project).to_discussion
    end

    let_it_be(:second_discussion) do
      create(:discussion_note_on_merge_request, noteable: merge_request, project: project).to_discussion
    end

    let(:first_discussion_selector) { ".discussion[data-discussion-id='#{first_discussion.id}']" }
    let(:second_discussion_selector) { ".discussion[data-discussion-id='#{second_discussion.id}']" }

    shared_examples 'a page with no code discussions' do
      describe "Changes page discussions navigation" do
        it 'navigates to the first discussion on the Overview page' do
          goto_next_thread
          expect(page).to have_selector(first_discussion_selector, obscured: false)
        end

        it 'navigates to the last discussion on the Overview page' do
          goto_previous_thread
          expect(page).to have_selector(second_discussion_selector, obscured: false)
        end
      end
    end

    context 'on changes page' do
      before do
        visit diffs_project_merge_request_path(project, merge_request)
      end

      it_behaves_like 'a page with no code discussions'
    end

    context 'on commits page' do
      before do
        # we can't go directly to the commits page since it doesn't load discussions
        visit project_merge_request_path(project, merge_request)
        within '.merge-request-tabs' do
          click_link 'Commits'
        end
      end

      it_behaves_like 'a page with no code discussions'
    end

    context 'on pipelines page' do
      before do
        visit project_merge_request_path(project, merge_request)
        click_link 'Pipelines'
      end

      it_behaves_like 'a page with no code discussions'
    end
  end

  def goto_next_thread
    click_button 'Next unresolved thread', obscured: false
    # Wait for scroll
    sleep(1)
  end

  def goto_previous_thread
    click_button 'Previous unresolved thread', obscured: false
    # Wait for scroll
    sleep(1)
  end
end
