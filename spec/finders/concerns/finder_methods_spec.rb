# frozen_string_literal: true

require 'spec_helper'

RSpec.describe FinderMethods do
  let(:finder_class) do
    Class.new do
      include FinderMethods

      def initialize(user)
        @current_user = user
      end

      def execute
        Project.where.not(name: 'foo').order(id: :desc)
      end

      private

      attr_reader :current_user
    end
  end

  let_it_be(:user) { create(:user) }
  let_it_be(:authorized_project) { create(:project, developers: user) }
  let_it_be(:unmatched_project) { create(:project, name: 'foo', developers: user) }
  let_it_be(:unauthorized_project) { create(:project) }

  subject(:finder) { finder_class.new(user) }

  # rubocop:disable Rails/FindById
  describe '#find_by!' do
    it 'returns the project if the user has access' do
      expect(finder.find_by!(id: authorized_project.id)).to eq(authorized_project)
    end

    it 'raises not found when the project is not found by id' do
      expect { finder.find_by!(id: non_existing_record_id) }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it 'raises not found when the project is not found by filter' do
      expect { finder.find_by!(id: unmatched_project.id) }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it 'raises not found the user does not have access' do
      expect { finder.find_by!(id: unauthorized_project.id) }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it 'ignores ordering' do
      # Memoise the finder result so we can add message expectations to it
      relation = finder.execute
      allow(finder).to receive(:execute).and_return(relation)

      expect(relation).to receive(:reorder).with(nil).and_call_original

      finder.find_by!(id: authorized_project.id)
    end
  end
  # rubocop:enable Rails/FindById

  describe '#find' do
    it 'returns the project if the user has access' do
      expect(finder.find(authorized_project.id)).to eq(authorized_project)
    end

    it 'raises not found when the project is not found by id' do
      expect { finder.find(non_existing_record_id) }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it 'raises not found when the project is not found by filter' do
      expect { finder.find(unmatched_project.id) }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it 'raises not found the user does not have access' do
      expect { finder.find(unauthorized_project.id) }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it 'ignores ordering' do
      # Memoise the finder result so we can add message expectations to it
      relation = finder.execute
      allow(finder).to receive(:execute).and_return(relation)

      expect(relation).to receive(:reorder).with(nil).and_call_original

      finder.find(authorized_project.id)
    end
  end

  describe '#find_by' do
    it 'returns the project if the user has access' do
      expect(finder.find_by(id: authorized_project.id)).to eq(authorized_project)
    end

    it 'returns nil when the project is not found by id' do
      expect(finder.find_by(id: non_existing_record_id)).to be_nil
    end

    it 'returns nil when the project is not found by filter' do
      expect(finder.find_by(id: unmatched_project.id)).to be_nil
    end

    it 'returns nil when the user does not have access' do
      expect(finder.find_by(id: unauthorized_project.id)).to be_nil
    end

    it 'ignores ordering' do
      # Memoise the finder result so we can add message expectations to it
      relation = finder.execute
      allow(finder).to receive(:execute).and_return(relation)

      expect(relation).to receive(:reorder).with(nil).and_call_original

      finder.find_by(id: authorized_project.id)
    end
  end
end
