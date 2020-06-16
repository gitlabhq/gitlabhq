# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Autocomplete::GroupFinder do
  let(:user) { create(:user) }

  describe '#execute' do
    context 'with a project' do
      it 'returns nil' do
        project = create(:project)

        expect(described_class.new(user, project).execute).to be_nil
      end
    end

    context 'without a group ID' do
      it 'returns nil' do
        expect(described_class.new(user).execute).to be_nil
      end
    end

    context 'with an empty String as the group ID' do
      it 'returns nil' do
        expect(described_class.new(user, nil, group_id: '').execute).to be_nil
      end
    end

    context 'without a project and with a group ID' do
      it 'raises ActiveRecord::RecordNotFound if the group does not exist' do
        finder = described_class.new(user, nil, group_id: 1)

        expect { finder.execute }.to raise_error(ActiveRecord::RecordNotFound)
      end

      it 'raises ActiveRecord::RecordNotFound if the user can not read the group' do
        group = create(:group, :private)
        finder = described_class.new(user, nil, group_id: group.id)

        expect { finder.execute }.to raise_error(ActiveRecord::RecordNotFound)
      end

      it 'raises ActiveRecord::RecordNotFound if an anonymous user can not read the group' do
        group = create(:group, :private)
        finder = described_class.new(nil, nil, group_id: group.id)

        expect { finder.execute }.to raise_error(ActiveRecord::RecordNotFound)
      end

      it 'returns the group if it exists and is readable' do
        group = create(:group)
        finder = described_class.new(user, nil, group_id: group.id)

        expect(finder.execute).to eq(group)
      end
    end
  end
end
