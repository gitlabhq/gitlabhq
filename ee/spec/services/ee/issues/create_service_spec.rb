# frozen_string_literal: true

require 'spec_helper'

describe Issues::CreateService do
  let(:group)   { create(:group) }
  let(:project) { create(:project, group: group) }
  let(:user)    { create(:user) }

  let(:issue) { described_class.new(project, user, opts).execute }

  before do
    stub_licensed_features(epics: true)

    project.add_maintainer(user)
  end

  context 'quick actions' do
    context '/epic action' do
      let(:epic) { create(:epic, group: group) }
      let(:opts) do
        {
          title: 'New issue',
          description: "/epic #{epic.to_reference(project)}"
        }
      end

      it 'adds an issue to the passed epic' do
        expect(issue).to be_persisted
        expect(issue.epic).to eq(epic)
      end
    end
  end
end
