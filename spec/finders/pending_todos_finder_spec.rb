# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PendingTodosFinder, feature_category: :notifications do
  let_it_be(:user) { create(:user) }
  let_it_be(:user2) { create(:user) }
  let_it_be(:user3) { create(:user) }
  let_it_be(:banned_user) { create(:user, :banned) }
  let_it_be(:issue) { create(:issue) }
  let_it_be(:issue2) { create(:issue) }
  let_it_be(:project) { create(:project) }
  let_it_be(:note) { create(:note) }
  let_it_be(:todo) { create(:todo, :pending, user: user, target: issue) }
  let_it_be(:todo2) { create(:todo, :pending, user: user, target: issue2, project: project) }
  let_it_be(:todo3) { create(:todo, :pending, user: user2, target: issue) }
  let_it_be(:todo4) { create(:todo, :pending, user: user3, target: issue) }
  let_it_be(:banned_pending_todo) { create(:todo, :pending, user: user, target: issue, author: banned_user) }
  let_it_be(:done_todo) { create(:todo, :done, user: user) }

  let(:users) { [user, user2] }

  describe '#execute' do
    it 'returns all non-hidden pending todos if no params are passed' do
      todos = described_class.new.execute

      expect(todos).to match_array([todo, todo2, todo3, todo4])
    end

    it 'supports retrieving only pending todos for chosen users' do
      todos = described_class.new(users: users).execute

      expect(todos).to match_array([todo, todo2, todo3])
    end

    it 'supports retrieving of todos for a specific project' do
      project2 = create(:project)
      project2_todo = create(:todo, :pending, user: user, project: project2)

      todos = described_class.new(users: user, project_id: project.id).execute
      expect(todos).to match_array([todo2])

      todos = described_class.new(users: user, project_id: project2.id).execute
      expect(todos).to match_array([project2_todo])
    end

    it 'supports retrieving of todos for a specific todo target' do
      todos = described_class.new(users: user, target_id: issue.id, target_type: 'Issue').execute

      expect(todos).to match_array([todo])
    end

    it 'supports retrieving of todos for a specific target type' do
      todos = described_class.new(users: user, target_type: issue.class.name).execute

      expect(todos).to match_array([todo, todo2])
    end

    it 'supports retrieving of todos from a specific author' do
      todo = create(:todo, :pending, user: user, author: user2, target: issue)
      create(:todo, :pending, user: user, author: user3, target: issue)

      todos = described_class.new(users: users, author_id: user2.id).execute

      expect(todos).to eq([todo])
    end

    it 'supports retrieving of todos for a specific commit ID' do
      create(:todo, :pending, user: user, commit_id: '456')

      todo = create(:todo, :pending, user: user, commit_id: '123')
      todos = described_class.new(users: users, commit_id: '123').execute

      expect(todos).to eq([todo])
    end

    it 'supports retrieving of todos for specific discussion' do
      first_discussion_note = create(:discussion_note_on_issue, noteable: issue, project: issue.project)
      note_2 = create(:note, discussion_id: first_discussion_note.discussion_id)
      note_3 = create(:note, discussion_id: first_discussion_note.discussion_id)
      todo1 = create(:todo, :pending, target: issue, note: note_2, user: note_2.author)
      todo2 = create(:todo, :pending, target: issue, note: note_3, user: note_3.author)

      # Create a second discussion on the same issue
      second_discussion_note = create(:discussion_note_on_issue, noteable: issue, project: issue.project)
      todo3 = create(:todo, :pending, target: issue, note: second_discussion_note, user: second_discussion_note.author)

      create(:todo, :pending, note: note, user: user)
      discussion = Discussion.lazy_find(first_discussion_note.discussion_id)
      users = [note_2.author, note_3.author, user]

      todos = described_class.new(users: users, discussion: discussion).execute

      expect(todos).to contain_exactly(todo1, todo2)
      expect(todos).not_to include(todo3)
    end

    it 'supports retrieving of todos for a specific action' do
      todo = create(:todo, :pending, user: user, target: issue, action: Todo::MENTIONED)

      create(:todo, :pending, user: user, target: issue, action: Todo::ASSIGNED)

      todos = described_class.new(users: users, action: Todo::MENTIONED).execute

      expect(todos).to contain_exactly(todo)
    end
  end
end
