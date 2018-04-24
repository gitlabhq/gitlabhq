require 'spec_helper'

feature 'Dashboard Todos' do
  let(:user)    { create(:user) }
  let(:author)  { create(:user) }
  let(:project) { create(:project, :public) }
  let(:issue)   { create(:issue, due_date: Date.today) }

  context 'User does not have todos' do
    before do
      sign_in(user)
      visit dashboard_todos_path
    end

    it 'shows "All done" message' do
      expect(page).to have_content 'Todos let you see what you should do next'
    end
  end

  context 'User has a todo', :js do
    before do
      create(:todo, :mentioned, user: user, project: project, target: issue, author: author)
      sign_in(user)

      visit dashboard_todos_path
    end

    it 'has todo present' do
      expect(page).to have_selector('.todos-list .todo', count: 1)
    end

    it 'shows due date as today' do
      within first('.todo') do
        expect(page).to have_content 'Due today'
      end
    end

    shared_examples 'deleting the todo' do
      before do
        within first('.todo') do
          click_link 'Done'
        end
      end

      it 'is marked as done-reversible in the list' do
        expect(page).to have_selector('.todos-list .todo.todo-pending.done-reversible')
      end

      it 'shows Undo button' do
        expect(page).to have_selector('.js-undo-todo', visible: true)
        expect(page).to have_selector('.js-done-todo', visible: false)
      end

      it 'updates todo count' do
        expect(page).to have_content 'Todos 0'
        expect(page).to have_content 'Done 1'
      end

      it 'has not "All done" message' do
        expect(page).not_to have_selector('.todos-all-done')
      end
    end

    shared_examples 'deleting and restoring the todo' do
      before do
        within first('.todo') do
          click_link 'Done'
          wait_for_requests
          click_link 'Undo'
        end
      end

      it 'is marked back as pending in the list' do
        expect(page).not_to have_selector('.todos-list .todo.todo-pending.done-reversible')
        expect(page).to have_selector('.todos-list .todo.todo-pending')
      end

      it 'shows Done button' do
        expect(page).to have_selector('.js-undo-todo', visible: false)
        expect(page).to have_selector('.js-done-todo', visible: true)
      end

      it 'updates todo count' do
        expect(page).to have_content 'Todos 1'
        expect(page).to have_content 'Done 0'
      end
    end

    it_behaves_like 'deleting the todo'
    it_behaves_like 'deleting and restoring the todo'

    context 'todo is stale on the page' do
      before do
        todos = TodosFinder.new(user, state: :pending).execute
        TodoService.new.mark_todos_as_done(todos, user)
      end

      it_behaves_like 'deleting the todo'
      it_behaves_like 'deleting and restoring the todo'
    end
  end

  context 'User created todos for themself' do
    before do
      sign_in(user)
    end

    context 'issue assigned todo' do
      before do
        create(:todo, :assigned, user: user, project: project, target: issue, author: user)
        visit dashboard_todos_path
      end

      it 'shows issue assigned to yourself message' do
        page.within('.js-todos-all')  do
          expect(page).to have_content("You assigned issue #{issue.to_reference(full: true)} to yourself")
        end
      end
    end

    context 'marked todo' do
      before do
        create(:todo, :marked, user: user, project: project, target: issue, author: user)
        visit dashboard_todos_path
      end

      it 'shows you added a todo message' do
        page.within('.js-todos-all')  do
          expect(page).to have_content("You added a todo for issue #{issue.to_reference(full: true)}")
          expect(page).not_to have_content('to yourself')
        end
      end
    end

    context 'mentioned todo' do
      before do
        create(:todo, :mentioned, user: user, project: project, target: issue, author: user)
        visit dashboard_todos_path
      end

      it 'shows you mentioned yourself message' do
        page.within('.js-todos-all')  do
          expect(page).to have_content("You mentioned yourself on issue #{issue.to_reference(full: true)}")
          expect(page).not_to have_content('to yourself')
        end
      end
    end

    context 'directly_addressed todo' do
      before do
        create(:todo, :directly_addressed, user: user, project: project, target: issue, author: user)
        visit dashboard_todos_path
      end

      it 'shows you directly addressed yourself message' do
        page.within('.js-todos-all')  do
          expect(page).to have_content("You directly addressed yourself on issue #{issue.to_reference(full: true)}")
          expect(page).not_to have_content('to yourself')
        end
      end
    end

    context 'approval todo' do
      let(:merge_request) { create(:merge_request) }

      before do
        create(:todo, :approval_required, user: user, project: project, target: merge_request, author: user)
        visit dashboard_todos_path
      end

      it 'shows you set yourself as an approver message' do
        page.within('.js-todos-all')  do
          expect(page).to have_content("You set yourself as an approver for merge request #{merge_request.to_reference(full: true)}")
          expect(page).not_to have_content('to yourself')
        end
      end
    end
  end

  context 'User has done todos', :js do
    before do
      create(:todo, :mentioned, :done, user: user, project: project, target: issue, author: author)
      sign_in(user)
      visit dashboard_todos_path(state: :done)
    end

    it 'has the done todo present' do
      expect(page).to have_selector('.todos-list .todo.todo-done', count: 1)
    end

    describe 'restoring the todo' do
      before do
        within first('.todo') do
          click_link 'Add todo'
        end
      end

      it 'is removed from the list' do
        expect(page).not_to have_selector('.todos-list .todo.todo-done')
      end

      it 'updates todo count' do
        expect(page).to have_content 'Todos 1'
        expect(page).to have_content 'Done 0'
      end
    end
  end

  context 'User has Todos with labels spanning multiple projects' do
    before do
      label1 = create(:label, project: project)
      note1 = create(:note_on_issue, note: "Hello #{label1.to_reference(format: :name)}", noteable_id: issue.id, noteable_type: 'Issue', project: issue.project)
      create(:todo, :mentioned, project: project, target: issue, user: user, note_id: note1.id)

      project2 = create(:project, :public)
      label2 = create(:label, project: project2)
      issue2 = create(:issue, project: project2)
      note2 = create(:note_on_issue, note: "Test #{label2.to_reference(format: :name)}", noteable_id: issue2.id, noteable_type: 'Issue', project: project2)
      create(:todo, :mentioned, project: project2, target: issue2, user: user, note_id: note2.id)

      gitlab_sign_in(user)
      visit dashboard_todos_path
    end

    it 'shows page with two Todos' do
      expect(page).to have_selector('.todos-list .todo', count: 2)
    end
  end

  context 'User has multiple pages of Todos' do
    before do
      allow(Todo).to receive(:default_per_page).and_return(1)

      # Create just enough records to cause us to paginate
      create_list(:todo, 2, :mentioned, user: user, project: project, target: issue, author: author)

      sign_in(user)
    end

    it 'is paginated' do
      visit dashboard_todos_path

      expect(page).to have_selector('.gl-pagination')
    end

    it 'is has the right number of pages' do
      visit dashboard_todos_path

      expect(page).to have_selector('.gl-pagination [data-test=page]', count: 2)
    end

    describe 'mark all as done', :js do
      before do
        visit dashboard_todos_path
        find('.js-todos-mark-all').click
      end

      it 'shows "All done" message!' do
        expect(page).to have_content 'Todos 0'
        expect(page).to have_content "You're all done!"
        expect(page).not_to have_selector('.gl-pagination')
      end

      it 'shows "Undo mark all as done" button' do
        expect(page).to have_selector('.js-todos-mark-all', visible: false)
        expect(page).to have_selector('.js-todos-undo-all', visible: true)
      end
    end

    describe 'undo mark all as done', :js do
      before do
        visit dashboard_todos_path
      end

      it 'shows the restored todo list' do
        mark_all_and_undo

        expect(page).to have_selector('.todos-list .todo', count: 1)
        expect(page).to have_selector('.gl-pagination')
        expect(page).not_to have_content "You're all done!"
      end

      it 'updates todo count' do
        mark_all_and_undo

        expect(page).to have_content 'Todos 2'
        expect(page).to have_content 'Done 0'
      end

      it 'shows "Mark all as done" button' do
        mark_all_and_undo

        expect(page).to have_selector('.js-todos-mark-all', visible: true)
        expect(page).to have_selector('.js-todos-undo-all', visible: false)
      end

      context 'User has deleted a todo' do
        before do
          within first('.todo') do
            click_link 'Done'
          end
        end

        it 'shows the restored todo list with the deleted todo' do
          mark_all_and_undo

          expect(page).to have_selector('.todos-list .todo.todo-pending', count: 1)
        end
      end

      def mark_all_and_undo
        find('.js-todos-mark-all').click
        wait_for_requests
        find('.js-todos-undo-all').click
        wait_for_requests
      end
    end
  end

  context 'User has a Build Failed todo' do
    let!(:todo) { create(:todo, :build_failed, user: user, project: project, author: author) }

    before do
      sign_in(user)
      visit dashboard_todos_path
    end

    it 'shows the todo' do
      expect(page).to have_content 'The build failed for merge request'
    end

    it 'links to the pipelines for the merge request' do
      href = pipelines_project_merge_request_path(project, todo.target)

      expect(page).to have_link "merge request #{todo.target.to_reference(full: true)}", href
    end
  end
end
