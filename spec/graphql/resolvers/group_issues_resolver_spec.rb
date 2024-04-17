# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::GroupIssuesResolver do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }

  let_it_be(:group)         { create(:group, developers: current_user) }
  let_it_be(:project)       { create(:project, group: group) }
  let_it_be(:other_project) { create(:project, group: group) }
  let_it_be(:subgroup)      { create(:group, parent: group, developers: current_user) }
  let_it_be(:subproject)    { create(:project, group: subgroup) }

  let_it_be(:issue1)    { create(:incident, project: project, state: :opened, created_at: 3.hours.ago, updated_at: 3.hours.ago) }
  let_it_be(:issue2)    { create(:issue, project: project, state: :closed, title: 'foo', created_at: 1.hour.ago, updated_at: 1.hour.ago, closed_at: 1.hour.ago) }
  let_it_be(:issue3)    { create(:issue, project: other_project, state: :closed, title: 'foo', created_at: 1.hour.ago, updated_at: 1.hour.ago, closed_at: 1.hour.ago) }
  let_it_be(:issue4)    { create(:issue) }

  let_it_be(:subissue1) { create(:issue, project: subproject) }
  let_it_be(:subissue2) { create(:issue, project: subproject) }
  let_it_be(:subissue3) { create(:issue, project: subproject) }

  describe '#resolve' do
    it 'finds all group issues' do
      expect(resolve_issues).to contain_exactly(issue1, issue2, issue3)
    end

    it 'finds all group and subgroup issues' do
      result = resolve_issues(include_subgroups: true)

      expect(result).to contain_exactly(issue1, issue2, issue3, subissue1, subissue2, subissue3)
    end

    it 'returns issues without the specified issue_type' do
      result = resolve_issues(not: { types: ['issue'] })

      expect(result).to contain_exactly(issue1)
    end

    context 'confidential issues' do
      let_it_be(:confidential_issue1) { create(:issue, project: project, confidential: true) }
      let_it_be(:confidential_issue2) { create(:issue, project: other_project, confidential: true) }

      context "when user is allowed to view confidential issues" do
        it 'returns all viewable issues by default' do
          expect(resolve_issues).to contain_exactly(issue1, issue2, issue3, confidential_issue1, confidential_issue2)
        end

        context 'filtering for confidential issues' do
          it 'returns only the non-confidential issues for the group when filter is set to false' do
            expect(resolve_issues({ confidential: false })).to contain_exactly(issue1, issue2, issue3)
          end

          it "returns only the confidential issues for the group when filter is set to true" do
            expect(resolve_issues({ confidential: true })).to contain_exactly(confidential_issue1, confidential_issue2)
          end
        end
      end

      context "when user is not allowed to see confidential issues" do
        before do
          group.add_guest(current_user)
        end

        it 'returns all viewable issues by default' do
          expect(resolve_issues).to contain_exactly(issue1, issue2, issue3)
        end

        context 'filtering for confidential issues' do
          it 'does not return the confidential issues when filter is set to false' do
            expect(resolve_issues({ confidential: false })).to contain_exactly(issue1, issue2, issue3)
          end

          it 'does not return the confidential issues when filter is set to true' do
            expect(resolve_issues({ confidential: true })).to be_empty
          end
        end
      end
    end

    context 'release_tag filter' do
      it 'generates an error when trying to filter by negated release_tag' do
        expect_graphql_error_to_be_created(Gitlab::Graphql::Errors::ArgumentError, 'releaseTag filter is not allowed when parent is a group.') do
          resolve_issues(not: { release_tag: ['v1.0'] })
        end
      end
    end
  end

  def resolve_issues(args = {}, context = { current_user: current_user })
    resolve(described_class, obj: group, args: args, ctx: context)
  end
end
