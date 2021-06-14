# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PendingTodosFinder do
  let_it_be(:user) { create(:user) }
  let_it_be(:user2) { create(:user) }
  let_it_be(:issue) { create(:issue) }
  let_it_be(:note) { create(:note) }

  let(:users) { [user, user2] }

  describe '#execute' do
    it 'returns only pending todos' do
      create(:todo, :done, user: user)

      todo = create(:todo, :pending, user: user)
      todos = described_class.new(users).execute

      expect(todos).to eq([todo])
    end

    it 'supports retrieving of todos for a specific project' do
      project1 = create(:project)
      project2 = create(:project)

      create(:todo, :pending, user: user, project: project2)

      todo = create(:todo, :pending, user: user, project: project1)
      todos = described_class.new(users, project_id: project1.id).execute

      expect(todos).to eq([todo])
    end

    it 'supports retrieving of todos for a specific todo target' do
      todo = create(:todo, :pending, user: user, target: issue)

      create(:todo, :pending, user: user, target: note)

      todos = described_class.new(users, target_id: issue.id, target_type: 'Issue').execute

      expect(todos).to eq([todo])
    end

    it 'supports retrieving of todos for a specific target type' do
      todo = create(:todo, :pending, user: user, target: issue)

      create(:todo, :pending, user: user, target: note)

      todos = described_class.new(users, target_type: issue.class.name).execute

      expect(todos).to eq([todo])
    end

    it 'supports retrieving of todos for a specific commit ID' do
      create(:todo, :pending, user: user, commit_id: '456')

      todo = create(:todo, :pending, user: user, commit_id: '123')
      todos = described_class.new(users, commit_id: '123').execute

      expect(todos).to eq([todo])
    end

    it 'supports retrieving of todos for specific discussion' do
      first_discussion_note = create(:discussion_note_on_issue, noteable: issue, project: issue.project)
      note_2 = create(:note, discussion_id: first_discussion_note.discussion_id)
      note_3 = create(:note, discussion_id: first_discussion_note.discussion_id)
      todo1 = create(:todo, :pending, target: issue, note: note_2, user: note_2.author)
      todo2 = create(:todo, :pending, target: issue, note: note_3, user: note_3.author)
      create(:todo, :pending, note: note, user: user)
      discussion = Discussion.lazy_find(first_discussion_note.discussion_id)
      users = [note_2.author, note_3.author, user]

      todos = described_class.new(users, discussion: discussion).execute

      expect(todos).to contain_exactly(todo1, todo2)
    end
  end
end
