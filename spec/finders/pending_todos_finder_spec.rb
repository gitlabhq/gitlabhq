# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PendingTodosFinder do
  let(:user) { create(:user) }
  let(:user2) { create(:user) }
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
      issue = create(:issue)
      note = create(:note)
      todo = create(:todo, :pending, user: user, target: issue)

      create(:todo, :pending, user: user, target: note)

      todos = described_class.new(users, target_id: issue.id).execute

      expect(todos).to eq([todo])
    end

    it 'supports retrieving of todos for a specific target type' do
      issue = create(:issue)
      note = create(:note)
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
  end
end
