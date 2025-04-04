# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MilestonesHelper, feature_category: :team_planning do
  let_it_be(:issuable) { build(:merge_request) }
  let_it_be(:group) { build_stubbed(:group) }
  let_it_be(:project_namespace) { build_stubbed(:project_namespace) }
  let_it_be(:project_issuable) { build_stubbed(:work_item, namespace: project_namespace) }
  let_it_be(:group_issuable) { build_stubbed(:work_item, namespace: group) }

  describe '#milestone_header_class' do
    using RSpec::Parameterized::TableSyntax

    color_primary = 'gl-bg-blue-500 gl-text-white'
    border_empty = 'gl-border-b-0 gl-rounded-base'

    where(:primary, :issuables, :header_color, :header_border) do
      true  | [issuable] | color_primary | ''
      true  | []         | color_primary | border_empty
      false | []         | ''            | border_empty
      false | [issuable] | ''            | ''
    end

    with_them do
      subject { helper.milestone_header_class(primary, issuables) }

      it { is_expected.to eq("#{header_color} #{header_border} gl-flex") }
    end
  end

  describe '#milestone_counter_class' do
    context 'when primary is set to true' do
      subject { helper.milestone_counter_class(true) }

      it { is_expected.to eq('gl-text-white') }
    end

    context 'when primary is set to false' do
      subject { helper.milestone_counter_class(false) }

      it { is_expected.to eq('gl-text-subtle') }
    end
  end

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
