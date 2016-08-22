require 'spec_helper'

describe TodosFinder do
  describe '#execute' do
    let(:user)          { create(:user) }
    let(:project)       { create(:empty_project) }
    let(:finder)        { described_class }

    before { project.team << [user, :developer] }

    describe '#sort' do
      context 'by date' do
        let!(:todo1) { create(:todo, user: user, project: project) }
        let!(:todo2) { create(:todo, user: user, project: project) }
        let!(:todo3) { create(:todo, user: user, project: project) }

        it 'sorts with oldest created first' do
          todos = finder.new(user, { sort: 'id_asc' }).execute

          expect(todos.first).to eq(todo1)
          expect(todos.second).to eq(todo2)
          expect(todos.third).to eq(todo3)
        end

        it 'sorts with newest created first' do
          todos = finder.new(user, { sort: 'id_desc' }).execute

          expect(todos.first).to eq(todo3)
          expect(todos.second).to eq(todo2)
          expect(todos.third).to eq(todo1)
        end
      end

      it "sorts by priority" do
        label_1         = create(:label, title: 'label_1', project: project, priority: 1)
        label_2         = create(:label, title: 'label_2', project: project, priority: 2)
        label_3         = create(:label, title: 'label_3', project: project, priority: 3)

        issue_1         = create(:issue, title: 'issue_1', project: project)
        issue_2         = create(:issue, title: 'issue_2', project: project)
        issue_3         = create(:issue, title: 'issue_3', project: project)
        issue_4         = create(:issue, title: 'issue_4', project: project)
        merge_request_1 = create(:merge_request, source_project: project)

        merge_request_1.labels << label_1

        # Covers the case where Todo has more than one label
        issue_3.labels         << label_1
        issue_3.labels         << label_3

        issue_2.labels         << label_3
        issue_1.labels         << label_2

        todo_1 = create(:todo, user: user, project: project, target: issue_4)
        todo_2 = create(:todo, user: user, project: project, target: issue_2)
        todo_3 = create(:todo, user: user, project: project, target: issue_3, created_at: 2.hours.ago)
        todo_4 = create(:todo, user: user, project: project, target: issue_1)
        todo_5 = create(:todo, user: user, project: project, target: merge_request_1, created_at: 1.hour.ago)

        todos = finder.new(user, { sort: 'priority' }).execute

        expect(todos.first).to eq(todo_3)
        expect(todos.second).to eq(todo_5)
        expect(todos.third).to eq(todo_4)
        expect(todos.fourth).to eq(todo_2)
        expect(todos.fifth).to eq(todo_1)
      end
    end
  end
end
