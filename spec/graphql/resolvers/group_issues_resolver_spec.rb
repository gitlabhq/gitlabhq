# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::GroupIssuesResolver do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }

  let_it_be(:group)         { create(:group) }
  let_it_be(:project)       { create(:project, group: group) }
  let_it_be(:other_project) { create(:project, group: group) }
  let_it_be(:subgroup)      { create(:group, parent: group) }
  let_it_be(:subproject)    { create(:project, group: subgroup) }

  let_it_be(:issue1)    { create(:incident, project: project, state: :opened, created_at: 3.hours.ago, updated_at: 3.hours.ago) }
  let_it_be(:issue2)    { create(:issue, project: project, state: :closed, title: 'foo', created_at: 1.hour.ago, updated_at: 1.hour.ago, closed_at: 1.hour.ago) }
  let_it_be(:issue3)    { create(:issue, project: other_project, state: :closed, title: 'foo', created_at: 1.hour.ago, updated_at: 1.hour.ago, closed_at: 1.hour.ago) }
  let_it_be(:issue4)    { create(:issue) }

  let_it_be(:subissue1) { create(:issue, project: subproject) }
  let_it_be(:subissue2) { create(:issue, project: subproject) }
  let_it_be(:subissue3) { create(:issue, project: subproject) }

  before_all do
    group.add_developer(current_user)
    subgroup.add_developer(current_user)
  end

  describe '#resolve' do
    it 'finds all group issues' do
      result = resolve(described_class, obj: group, ctx: { current_user: current_user })

      expect(result).to contain_exactly(issue1, issue2, issue3)
    end

    it 'finds all group and subgroup issues' do
      result = resolve(described_class, obj: group, args: { include_subgroups: true }, ctx: { current_user: current_user })

      expect(result).to contain_exactly(issue1, issue2, issue3, subissue1, subissue2, subissue3)
    end
  end
end
