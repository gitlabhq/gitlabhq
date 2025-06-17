# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TodosFinder, feature_category: :notifications do
  describe '#execute' do
    let_it_be(:user) { create(:user) }
    let_it_be(:group) { create(:group) }
    let_it_be(:project) { create(:project, :repository, namespace: group) }
    let_it_be(:issue) { create(:issue, project: project) }
    let_it_be(:merge_request) { create(:merge_request, source_project: project) }
    let_it_be(:banned_user) { create(:user, :banned) }

    before_all do
      group.add_developer(user)
    end

    describe '#execute' do
      it 'returns no todos if user is nil' do
        expect(execute(users: nil)).to be_empty
      end

      context 'when users is not passed' do
        it 'raises an argument error' do
          expect { described_class.new.execute }.to raise_error(ArgumentError)
        end
      end

      context 'with filtering' do
        let!(:todo1) { create(:todo, user: user, project: project, target: issue) }
        let!(:todo2) { create(:todo, user: user, group: group, target: merge_request) }
        let!(:banned_pending_todo) do
          create(:todo, :pending, user: user, project: project, target: issue, author: banned_user)
        end

        it 'returns excluding pending todos authored by banned users' do
          expect(execute).to match_array([todo1, todo2])
        end

        it 'returns correct todos when filtered by a project' do
          expect(execute(project_id: project.id)).to match_array([todo1])
        end

        it 'returns correct todos when filtered by a group' do
          expect(execute(group_id: group.id)).to match_array([todo1, todo2])
        end

        context 'with multiple users sent to the finder' do
          it 'returns correct todos for the users passed' do
            todo3 = create(:todo)
            user2 = todo3.user
            create(:todo)

            expect(execute(users: [user, user2])).to match_array([todo1, todo2, todo3])
          end
        end

        context 'when filtering by type' do
          it 'returns todos by type when filtered by a single type' do
            expect(execute(type: 'Issue')).to match_array([todo1])
          end

          it 'returns todos by type when filtered by multiple types' do
            create(:todo, user: user, group: group, target: create(:design))

            expect(execute(type: %w[Issue MergeRequest])).to contain_exactly(todo1, todo2)
          end

          it 'returns all todos when type is nil' do
            expect(execute(type: nil)).to contain_exactly(todo1, todo2)
          end

          it 'returns all todos when type is an empty collection' do
            expect(execute(type: [])).to contain_exactly(todo1, todo2)
          end

          it 'returns all todos when type is blank' do
            expect(execute(type: '')).to contain_exactly(todo1, todo2)
          end

          it 'returns todos by type when blank type is in type collection' do
            expect(execute(type: ['', 'MergeRequest'])).to contain_exactly(todo2)
          end

          it 'returns todos of all types when only blanks are in a collection' do
            expect(execute(type: ['', ''])).to contain_exactly(todo1, todo2)
          end

          it 'raises an argument error when invalid type is passed' do
            expect { execute(type: %w[Issue MergeRequest NotAValidType]) }.to raise_error(ArgumentError)
          end
        end

        context 'when filtering for actions' do
          let!(:todo1) { create(:todo, user: user, project: project, target: issue, action: Todo::ASSIGNED) }
          let!(:todo2) do
            create(:todo, user: user, group: group, target: merge_request, action: Todo::DIRECTLY_ADDRESSED)
          end

          context 'with by action ids' do
            it 'returns the expected todos' do
              expect(execute(action_id: Todo::DIRECTLY_ADDRESSED)).to match_array([todo2])
            end

            it 'returns the expected todos when filtering for multiple action ids' do
              expect(execute(action_id: [Todo::DIRECTLY_ADDRESSED, Todo::ASSIGNED])).to match_array([todo2, todo1])
            end
          end

          context 'with by action names' do
            it 'returns the expected todos' do
              expect(execute(action: :directly_addressed)).to match_array([todo2])
            end

            it 'returns the expected todos when filtering for multiple action names' do
              expect(execute(action: [:directly_addressed, :assigned])).to match_array([todo2, todo1])
            end
          end
        end

        context 'when filtering by author' do
          let_it_be(:author1) { create(:user) }
          let_it_be(:author2) { create(:user) }

          let!(:todo1) { create(:todo, user: user, author: author1) }
          let!(:todo2) { create(:todo, user: user, author: author2) }

          it 'returns correct todos when filtering by an author' do
            expect(execute(author_id: author1.id)).to match_array([todo1])
          end

          context 'with querying for multiple authors' do
            it 'returns the correct todo items' do
              expect(execute(author_id: [author2.id, author1.id])).to match_array([todo2, todo1])
            end
          end
        end

        context 'with by groups' do
          context 'with subgroups' do
            let_it_be(:subgroup) { create(:group, parent: group) }

            let!(:todo3) { create(:todo, user: user, group: subgroup, target: issue) }

            it 'returns todos from subgroups when filtered by a group' do
              expect(execute(group_id: group.id)).to match_array([todo1, todo2, todo3])
            end
          end

          context 'with filtering for multiple groups' do
            let_it_be(:group2) { create(:group) }
            let_it_be(:group3) { create(:group) }
            let_it_be(:subgroup1) { create(:group, parent: group) }
            let_it_be(:subgroup2) { create(:group, parent: group2) }

            let!(:todo1) { create(:todo, user: user, project: project, target: issue) }
            let!(:todo2) { create(:todo, user: user, group: group, target: merge_request) }
            let!(:todo3) { create(:todo, user: user, group: group2, target: merge_request) }
            let!(:todo4) { create(:todo, user: user, group: subgroup1, target: issue) }
            let!(:todo5) { create(:todo, user: user, group: subgroup2, target: issue) }
            let!(:todo6) { create(:todo, user: user, group: group3, target: issue) }

            it 'returns the expected groups' do
              expect(execute(group_id: [group.id, group2.id])).to match_array([todo1, todo2, todo3, todo4, todo5])
            end
          end
        end

        context 'with by state' do
          let!(:todo1) { create(:todo, user: user, group: group, target: issue, state: :done) }
          let!(:todo2) { create(:todo, user: user, group: group, target: issue, state: :done, author: banned_user) }
          let!(:todo3) { create(:todo, user: user, group: group, target: issue, state: :pending) }
          let!(:todo4) { create(:todo, user: user, group: group, target: issue, state: :pending, author: banned_user) }
          let!(:todo5) do
            create(:todo, user: user, group: group, target: issue, state: :pending, snoozed_until: 1.hour.from_now)
          end

          let!(:todo6) do
            create(:todo, user: user, group: group, target: issue, state: :pending, snoozed_until: 1.hour.ago)
          end

          it 'returns the expected items when no state is provided' do
            expect(execute).to match_array([todo3, todo6])
          end

          it 'returns the expected items when a state is provided' do
            expect(execute(state: :done)).to match_array([todo1, todo2])
          end

          it 'returns the expected items when multiple states are provided' do
            expect(execute(state: [:pending, :done])).to match_array([todo1, todo2, todo3, todo5, todo6])
          end
        end

        context 'with by snoozed state' do
          let_it_be(:todo1) { create(:todo, user: user, group: group, target: issue, state: :pending) }
          let_it_be(:todo2) do
            create(:todo, user: user, group: group, target: issue, state: :pending, snoozed_until: 1.hour.from_now)
          end

          let_it_be(:todo3) do
            create(:todo, user: user, group: group, target: issue, state: :pending, snoozed_until: 1.hour.ago)
          end

          it 'returns the snoozed todos only' do
            expect(execute(is_snoozed: true)).to match_array([todo2])
          end
        end

        context 'with by project' do
          let_it_be(:project1) { create(:project) }
          let_it_be(:project2) { create(:project) }
          let_it_be(:project3) { create(:project) }

          let!(:todo1) { create(:todo, user: user, project: project1, state: :pending) }
          let!(:todo2) { create(:todo, user: user, project: project2, state: :pending) }
          let!(:todo3) { create(:todo, user: user, project: project3, state: :pending) }

          it 'returns the expected todos for one project' do
            expect(execute(project_id: project2.id)).to match_array([todo2])
          end

          it 'returns the expected todos for many projects' do
            expect(execute(project_id: [project2.id, project1.id])).to match_array([todo2, todo1])
          end
        end

        context 'when filtering by target id' do
          it 'returns the expected todos for the target' do
            expect(execute(type: 'Issue', target_id: issue.id)).to match_array([todo1])
          end

          it 'returns the expected todos for multiple target ids' do
            another_issue = create(:issue, project: project)
            todo3 = create(:todo, user: user, project: project, target: another_issue)

            expect(execute(type: 'Issue', target_id: [issue.id, another_issue.id])).to match_array([todo1, todo3])
          end

          it 'returns the expected todos for empty target id collection' do
            expect(execute(target_id: [])).to match_array([todo1, todo2])
          end
        end
      end

      context 'with external authorization' do
        it_behaves_like 'a finder with external authorization service' do
          let!(:subject) { create(:todo, project: project, user: user) } # rubocop:disable RSpec/SubjectDeclaration -- In context subject is the right word
          let(:execute) { described_class.new(users: user).execute }
          let(:project_execute) { described_class.new(users: user, project_id: project.id).execute }
        end
      end
    end

    describe '#sort' do
      context 'with by date' do
        let!(:todo1) { create(:todo, user: user, project: project) }
        let!(:todo2) { create(:todo, user: user, project: project, created_at: 3.hours.ago) }
        let!(:todo3) { create(:todo, user: user, project: project, snoozed_until: 1.hour.ago) }

        context 'when sorting by ascending date' do
          subject { execute(sort: :created_asc) }

          it { is_expected.to eq([todo2, todo3, todo1]) }
        end

        context 'when sorting by descending date' do
          subject { execute(sort: :created_desc) }

          it { is_expected.to eq([todo1, todo3, todo2]) }
        end

        context 'when not querying pending to-dos only' do
          context 'when sorting by ascending date' do
            subject { execute(sort: :created_asc, state: [:done, :pending]) }

            it { is_expected.to eq([todo1, todo2, todo3]) }
          end

          context 'when sorting by descending date' do
            subject { execute(sort: :created_desc, state: [:done, :pending]) }

            it { is_expected.to eq([todo3, todo2, todo1]) }
          end
        end
      end

      it 'sorts by priority' do
        project_2 = create(:project)

        label_1         = create(:label, title: 'label_1', project: project, priority: 1)
        label_2         = create(:label, title: 'label_2', project: project, priority: 2)
        label_3         = create(:label, title: 'label_3', project: project, priority: 3)
        label_1_2       = create(:label, title: 'label_1', project: project_2, priority: 1)

        issue_1         = create(:issue, title: 'issue_1', project: project)
        issue_2         = create(:issue, title: 'issue_2', project: project)
        issue_3         = create(:issue, title: 'issue_3', project: project)
        issue_4         = create(:issue, title: 'issue_4', project: project)
        merge_request_1 = create(:merge_request, source_project: project_2)

        merge_request_1.labels << label_1_2

        # Covers the case where Todo has more than one label
        issue_3.labels         << label_1
        issue_3.labels         << label_3

        issue_2.labels         << label_3
        issue_1.labels         << label_2

        todo_1 = create(:todo, user: user, project: project, target: issue_4)
        todo_2 = create(:todo, user: user, project: project, target: issue_2)
        todo_3 = create(:todo, user: user, project: project, target: issue_3, created_at: 2.hours.ago)
        todo_4 = create(:todo, user: user, project: project, target: issue_1)
        todo_5 = create(:todo, user: user, project: project_2, target: merge_request_1, created_at: 1.hour.ago)

        project_2.add_developer(user)

        todos_asc_1 = execute(sort: :priority)
        expect(todos_asc_1).to eq([todo_3, todo_5, todo_4, todo_2, todo_1])

        todos_asc_2 = execute(sort: :label_priority_asc)
        expect(todos_asc_2).to eq([todo_3, todo_5, todo_4, todo_2, todo_1])

        todos_desc = execute(sort: :label_priority_desc)
        expect(todos_desc).to eq([todo_1, todo_2, todo_4, todo_5, todo_3])
      end
    end

    def execute(users: user, **kwargs)
      described_class.new(users: users, **kwargs).execute
    end
  end

  describe '.todo_types' do
    it 'returns the expected types' do
      shared_types = %w[Commit Issue WorkItem MergeRequest DesignManagement::Design AlertManagement::Alert Namespace
        Project Key WikiPage::Meta]

      expected_result =
        if Gitlab.ee?
          %w[Epic Vulnerability User] + shared_types
        else
          shared_types
        end

      expect(described_class.todo_types).to match_array(expected_result)
    end
  end
end
