require 'spec_helper'

describe FinderMethods do
  let(:finder_class) do
    Class.new do
      include FinderMethods

      attr_reader :current_user

      def initialize(user)
        @current_user = user
      end

      def execute
        Project.all
      end
    end
  end

  let(:user) { create(:user) }
  let(:finder) { finder_class.new(user) }
  let(:authorized_project) { create(:project) }
  let(:unauthorized_project) { create(:project) }

  before do
    authorized_project.add_developer(user)
  end

  describe '#find_by!' do
    it 'returns the project if the user has access' do
      expect(finder.find_by!(id: authorized_project.id)).to eq(authorized_project)
    end

    it 'raises not found when the project is not found' do
      expect { finder.find_by!(id: 0) }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it 'raises not found the user does not have access' do
      expect { finder.find_by!(id: unauthorized_project.id) }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  describe '#find' do
    it 'returns the project if the user has access' do
      expect(finder.find(authorized_project.id)).to eq(authorized_project)
    end

    it 'raises not found when the project is not found' do
      expect { finder.find(0) }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it 'raises not found the user does not have access' do
      expect { finder.find(unauthorized_project.id) }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  describe '#find_by' do
    it 'returns the project if the user has access' do
      expect(finder.find_by(id: authorized_project.id)).to eq(authorized_project)
    end

    it 'returns nil when the project is not found' do
      expect(finder.find_by(id: 0)).to be_nil
    end

    it 'returns nil when the user does not have access' do
      expect(finder.find_by(id: unauthorized_project.id)).to be_nil
    end
  end
end
