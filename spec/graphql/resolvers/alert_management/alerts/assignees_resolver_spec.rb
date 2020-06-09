# frozen_string_literal: true

require 'spec_helper'

describe Resolvers::AlertManagement::Alerts::AssigneesResolver do
  include GraphqlHelpers

  describe '#resolve' do
    let_it_be(:current_user) { create(:user) }
    let_it_be(:project) { create(:project) }
    let_it_be(:alert) { create(:alert_management_alert, :all_fields, project: project) }
    let_it_be(:another_alert) { create(:alert_management_alert, :all_fields, project: project) }

    it 'resolves for a single alert' do
      result = batch_sync(max_queries: 2) { resolve_assignees(alert) }

      expect(result).to match_array(alert.assignees)
    end

    it 'resolves for multiple alerts' do
      result = batch_sync(max_queries: 2) { [resolve_assignees(alert), resolve_assignees(another_alert)] }

      expect(result).to match_array([alert.assignees, another_alert.assignees])
    end

    private

    def resolve_assignees(alert, args = {}, context = { current_user: current_user })
      resolve(described_class, obj: alert, args: args, ctx: context)
    end
  end
end
