# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MilestonesHelper, feature_category: :team_planning do
  let_it_be(:issuable) { build(:merge_request) }
  let_it_be(:group) { build_stubbed(:group) }
  let_it_be(:project_namespace) { build_stubbed(:project_namespace) }
  let_it_be(:project_issuable) { build_stubbed(:work_item, namespace: project_namespace) }
  let_it_be(:group_issuable) { build_stubbed(:work_item, namespace: group) }

  describe '#milestone_issuable_group' do
    it 'returns nil for merge request' do
      expect(helper.milestone_issuable_group(issuable)).to be_nil
    end

    it 'returns group namespace' do
      expect(helper.milestone_issuable_group(group_issuable)).to eq(group)
    end

    it 'returns nil for project issuable' do
      expect(helper.milestone_issuable_group(project_issuable)).to be_nil
    end
  end
end
