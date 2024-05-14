# frozen_string_literal: true

RSpec.describe ActiveRecord::GitlabPatches::Relation::FindOrCreateBy do
  let(:model) do
    Class.new(Project) do
      validates :name, presence: true

      def self.name
        "Project"
      end
    end
  end

  describe '#find_or_create_by' do
    it 'does not trigger a subtransaction' do
      expect(model.find_by(id: 99990, name: 'project')).to be_nil
      expect(model.connection).not_to receive(:transaction).with(requires_new: true)

      project = model.find_or_create_by(id: 99990, name: 'project')
      expect(project).to be_present
    end

    it 'finds or creates the record' do
      expect(model.find_by(id: 99991, name: 'project')).to be_nil

      project = model.find_or_create_by(id: 99991, name: 'project')
      expect(project).to be_present

      expect(project).to eq(model.find_or_create_by(id: 99991, name: 'project'))
    end

    it 'does not raise error if validations are not met' do
      expect { model.find_or_create_by(id: 99992) }.not_to raise_error
    end
  end

  describe '#find_or_create_by!' do
    it 'does not trigger a subtransaction' do
      expect(model.find_by(id: 99993, name: 'project')).to be_nil

      expect(model.connection).not_to receive(:transaction).with(requires_new: true)

      project = model.find_or_create_by!(id: 99993, name: 'project')
      expect(project).to be_present
    end

    it 'finds or creates the record' do
      expect(model.find_by(id: 99994, name: 'project')).to be_nil

      project = model.find_or_create_by!(id: 99994, name: 'project')
      expect(project).to be_present

      expect(project).to eq(model.find_or_create_by!(id: 99994, name: 'project'))
    end

    it 'raises error if validations are not met' do
      expect { model.find_or_create_by!(id: 99995) }.to raise_error(ActiveRecord::RecordInvalid)
    end
  end
end
