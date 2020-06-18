# frozen_string_literal: true

require 'spec_helper'

RSpec.describe UsersWithPendingTodosFinder do
  describe '#execute' do
    it 'returns the users for all pending todos of a target' do
      issue = create(:issue)
      note = create(:note)
      todo = create(:todo, :pending, target: issue)

      create(:todo, :pending, target: note)

      users = described_class.new(issue).execute

      expect(users).to eq([todo.user])
    end
  end
end
