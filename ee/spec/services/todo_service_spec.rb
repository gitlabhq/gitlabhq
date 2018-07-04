require 'spec_helper'

describe TodoService do
  describe 'Epics' do
    let(:author) { create(:user, username: 'author') }
    let(:non_member) { create(:user, username: 'non_member') }
    let(:member) { create(:user, username: 'member') }
    let(:guest) { create(:user, username: 'guest') }
    let(:admin) { create(:admin, username: 'administrator') }
    let(:john_doe) { create(:user, username: 'john_doe') }
    let(:skipped) { create(:user, username: 'skipped') }
    let(:skip_users) { [skipped] }
    let(:users) { [author, non_member, member, guest, admin, john_doe, skipped] }
    let(:mentions) { users.map(&:to_reference).join(' ') }
    let(:combined_mentions) { member.to_reference + ", what do you think? cc: " + [guest, admin, skipped].map(&:to_reference).join(' ') }

    let(:description_mentions) { "- [ ] Task 1\n- [ ] Task 2 FYI: #{mentions}" }
    let(:description_directly_addressed) { "#{mentions}\n- [ ] Task 1\n- [ ] Task 2" }

    let(:group) { create(:group) }
    let(:epic) { create(:epic, group: group,  author: author, description: description_mentions) }

    let(:service) { described_class.new }

    let(:todos_for) { [] }
    let(:todos_not_for) { [] }
    let(:target) { epic }

    before do
      stub_licensed_features(epics: true)

      group.add_guest(guest)
      group.add_developer(author)
      group.add_developer(member)
    end

    shared_examples_for 'todos creation' do
      it 'creates todos for users mentioned' do
        if todos_for.count > 0
          params = todo_params
            .merge(user: todos_for)
            .reverse_merge(target: target, project: nil, group: group, author: author, state: :pending)

          expect { execute }
            .to change { Todo.where(params).count }.from(0).to(todos_for.count)
        end
      end

      it 'does not create todos for users not mentioned or without permissions' do
        execute

        params = todo_params
          .reverse_merge(target: target, project: nil, group: group, author: author, state: :pending)

        todos_not_for.each_with_index do |user, index|
          expect(Todo.where(params.merge(user: user)).count)
            .to eq(0), "expected not to create a todo for user '#{user.username}''"
        end
      end
    end

    context 'Epics' do
      describe '#new_epic' do
        let(:execute) { service.new_epic(epic, author) }

        context 'when an epic belongs to a public group' do
          context 'for mentioned users' do
            let(:todo_params) { { action: Todo::MENTIONED } }
            let(:todos_for) { users }

            include_examples 'todos creation'
          end

          context 'for directly addressed users' do
            before do
              epic.update(description: description_directly_addressed)
            end

            let(:todo_params) { { action: Todo::DIRECTLY_ADDRESSED } }
            let(:todos_for) { users }

            include_examples 'todos creation'
          end

          context 'combined' do
            before do
              epic.update(description: combined_mentions)
            end

            context 'mentioned users' do
              let(:todo_params) { { action: Todo::MENTIONED } }
              let(:todos_for) { [guest, admin, skipped] }

              include_examples 'todos creation'
            end

            context 'directly addressed users' do
              let(:todo_params) { { action: Todo::DIRECTLY_ADDRESSED } }
              let(:todos_for) { [member] }

              include_examples 'todos creation'
            end
          end
        end

        context 'when an epic belongs to a private group' do
          before do
            group.update(visibility: Gitlab::VisibilityLevel::PRIVATE)
          end

          context 'for mentioned users' do
            let(:todo_params) { { action: Todo::MENTIONED } }
            let(:todos_for) { [member, author, guest, admin] }
            let(:todos_not_for) { [non_member, john_doe, skipped] }

            include_examples 'todos creation'
          end

          context 'for directly addressed users' do
            before do
              epic.update!(description: description_directly_addressed)
            end

            let(:todo_params) { { action: Todo::DIRECTLY_ADDRESSED } }
            let(:todos_for) { [member, author, guest, admin] }
            let(:todos_not_for) { [non_member, john_doe, skipped] }

            include_examples 'todos creation'
          end
        end

        context 'creates todos for group members when a group is mentioned' do
          before do
            epic.update(description: group.to_reference)
          end

          let(:todo_params) { { action: Todo::DIRECTLY_ADDRESSED } }
          let(:todos_for) { [member, guest, author] }
          let(:todos_not_for) { [non_member, admin, john_doe] }

          include_examples 'todos creation'
        end
      end

      describe '#update_epic' do
        let(:execute) { service.update_epic(epic, author, skip_users) }

        context 'for mentioned users' do
          let(:todo_params) { { action: Todo::MENTIONED } }
          let(:todos_for) { [author, non_member, member, guest, admin, john_doe] }
          let(:todos_not_for) { [skipped] }

          include_examples 'todos creation'
        end

        context 'for directly addressed users' do
          before do
            epic.update(description: description_directly_addressed)
          end

          let(:todo_params) { { action: Todo::DIRECTLY_ADDRESSED } }
          let(:todos_for) { [author, non_member, member, guest, admin, john_doe] }
          let(:todos_not_for) { [skipped] }

          include_examples 'todos creation'
        end
      end

      describe '#new_note' do
        let!(:first_todo) do
          create(:todo, :assigned,
            user: john_doe, project: nil, group: group, target: epic, author: author)
        end
        let!(:second_todo) do
          create(:todo, :assigned,
            user: john_doe, project: nil, group: group, target: epic, author: author)
        end
        let(:note) { create(:note, noteable: epic, project: nil, author: john_doe, note: mentions) }

        context 'when a note is created for an epic' do
          it 'marks pending epic todos for the note author as done' do
            service.new_note(note, john_doe)

            expect(first_todo.reload).to be_done
            expect(second_todo.reload).to be_done
          end

          it 'does not marka pending epic todos for the note author as done for system notes' do
            system_note = create(:system_note, noteable: epic)

            service.new_note(system_note, john_doe)

            expect(first_todo.reload).to be_pending
            expect(second_todo.reload).to be_pending
          end
        end

        context 'mentions' do
          let(:execute) { service.new_note(note, author) }

          context 'for mentioned users' do
            before do
              note.update(note: description_mentions)
            end

            let(:todo_params) { { action: Todo::MENTIONED } }
            let(:todos_for) { [author, non_member, member, guest, admin, skipped] }
            let(:todos_not_for) { [john_doe] }

            include_examples 'todos creation'
          end

          context 'for directly addressed users' do
            before do
              note.update(note: description_directly_addressed)
            end

            let(:todo_params) { { action: Todo::DIRECTLY_ADDRESSED } }
            let(:todos_for) { [author, non_member, member, guest, admin, skipped] }
            let(:todos_not_for) { [john_doe] }

            include_examples 'todos creation'
          end

          context 'combined' do
            before do
              note.update(note: combined_mentions)
            end

            context 'mentioned users' do
              let(:todo_params) { { action: Todo::MENTIONED } }
              let(:todos_for) { [guest, admin, skipped] }

              include_examples 'todos creation'
            end

            context 'directly addressed users' do
              let(:todo_params) { { action: Todo::DIRECTLY_ADDRESSED } }
              let(:todos_for) { [member] }

              include_examples 'todos creation'
            end
          end
        end
      end
    end
  end
end
