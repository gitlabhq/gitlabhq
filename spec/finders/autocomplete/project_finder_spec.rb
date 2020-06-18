# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Autocomplete::ProjectFinder do
  let(:user) { create(:user) }

  describe '#execute' do
    context 'without a project ID' do
      it 'returns nil' do
        expect(described_class.new(user).execute).to be_nil
      end
    end

    context 'with an empty String as the project ID' do
      it 'returns nil' do
        expect(described_class.new(user, project_id: '').execute).to be_nil
      end
    end

    context 'with a project ID' do
      it 'raises ActiveRecord::RecordNotFound if the project does not exist' do
        finder = described_class.new(user, project_id: 1)

        expect { finder.execute }.to raise_error(ActiveRecord::RecordNotFound)
      end

      it 'raises ActiveRecord::RecordNotFound if the user can not read the project' do
        project = create(:project, :private)

        finder = described_class.new(user, project_id: project.id)

        expect { finder.execute }.to raise_error(ActiveRecord::RecordNotFound)
      end

      it 'raises ActiveRecord::RecordNotFound if an anonymous user can not read the project' do
        project = create(:project, :private)

        finder = described_class.new(nil, project_id: project.id)

        expect { finder.execute }.to raise_error(ActiveRecord::RecordNotFound)
      end

      it 'returns the project if it exists and is readable' do
        project = create(:project, :private)

        project.add_maintainer(user)

        finder = described_class.new(user, project_id: project.id)

        expect(finder.execute).to eq(project)
      end
    end
  end
end
