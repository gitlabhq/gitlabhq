require 'spec_helper'

describe Resolvers::IssuesResolver do
  include GraphqlHelpers

  let(:current_user) { create(:user) }
  set(:project) { create(:project) }
  set(:issue) { create(:issue, project: project) }
  set(:issue2) { create(:issue, project: project, title: 'foo') }

  before do
    project.add_developer(current_user)
  end

  describe '#resolve' do
    it 'finds all issues' do
      expect(resolve_issues).to contain_exactly(issue, issue2)
    end

    it 'searches issues' do
      expect(resolve_issues(search: 'foo')).to contain_exactly(issue2)
    end

    it 'sort issues' do
      expect(resolve_issues(sort: 'created_desc')).to eq [issue2, issue]
    end

    it 'returns issues user can see' do
      project.add_guest(current_user)

      create(:issue, confidential: true)

      expect(resolve_issues).to contain_exactly(issue, issue2)
    end
  end

  def resolve_issues(args = {}, context = { current_user: current_user })
    resolve(described_class, obj: project, args: args, ctx: context)
  end
end
