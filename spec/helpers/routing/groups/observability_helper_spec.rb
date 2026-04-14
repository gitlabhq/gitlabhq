# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Routing::Groups::ObservabilityHelper, feature_category: :observability do
  let_it_be(:group) { build_stubbed(:group) }

  describe '#group_observability_path' do
    where(:path) do
      [
        ['alerts'],
        ['alerts/edit'],
        ['services/my-service/top-level-operations'],
        ['dashboard/my-dashboard']
      ]
    end

    with_them do
      it 'generates the correct observability URL' do
        expect(helper.group_observability_path(group, path))
          .to eq("/groups/#{group.full_path}/-/observability/#{path}")
      end
    end

    it 'passes extra options through as query params' do
      expect(helper.group_observability_path(group, 'dashboard/my-dashboard', tab: 'overview'))
        .to eq("/groups/#{group.full_path}/-/observability/dashboard/my-dashboard?tab=overview")
    end
  end
end
