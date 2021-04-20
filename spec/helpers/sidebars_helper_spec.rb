# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SidebarsHelper do
  describe '#sidebar_tracking_attributes_by_object' do
    subject { helper.sidebar_tracking_attributes_by_object(object) }

    before do
      allow(helper).to receive(:tracking_enabled?).and_return(true)
    end

    context 'when object is a project' do
      let(:object) { build(:project) }

      it 'returns tracking attrs for project' do
        expect(subject[:data]).to eq({ track_label: 'projects_side_navigation', track_property: 'projects_side_navigation', track_action: 'render' })
      end
    end

    context 'when object is a group' do
      let(:object) { build(:group) }

      it 'returns tracking attrs for group' do
        expect(subject[:data]).to eq({ track_label: 'groups_side_navigation', track_property: 'groups_side_navigation', track_action: 'render' })
      end
    end

    context 'when object is a user' do
      let(:object) { build(:user) }

      it 'returns tracking attrs for user' do
        expect(subject[:data]).to eq({ track_label: 'user_side_navigation', track_property: 'user_side_navigation', track_action: 'render' })
      end
    end

    context 'when object is something else' do
      let(:object) { build(:ci_pipeline) }

      it 'returns no attributes' do
        expect(subject).to eq({})
      end
    end
  end
end
