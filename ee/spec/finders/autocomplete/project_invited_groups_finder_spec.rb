# frozen_string_literal: true

require 'spec_helper'

describe Autocomplete::ProjectInvitedGroupsFinder do
  let(:user) { create(:user) }

  describe '#execute' do
    context 'without a project ID' do
      it 'returns an empty relation' do
        expect(described_class.new(user).execute).to be_empty
      end
    end

    context 'with a project ID' do
      it 'returns the groups invited to the project' do
        project = create(:project, :public)
        group = create(:group)

        create(:project_group_link, project: project, group: group)

        expect(described_class.new(user, project_id: project.id).execute)
          .to eq([group])
      end
    end
  end
end
