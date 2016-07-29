require 'spec_helper'

describe MergeRequestsFinder do
  let(:user)  { create :user }
  let(:user2) { create :user }

  let(:project1) { create(:project) }
  let(:project2) { create(:project, forked_from_project: project1) }

  let!(:merge_request1) { create(:merge_request, :simple, author: user, source_project: project2, target_project: project1) }
  let!(:merge_request2) { create(:merge_request, :simple, author: user, source_project: project2, target_project: project1, state: 'closed') }
  let!(:merge_request3) { create(:merge_request, :simple, author: user, source_project: project2, target_project: project2) }

  before do
    project1.team << [user, :master]
    project2.team << [user, :developer]
    project2.team << [user2, :developer]
  end

  describe "#execute" do
    it 'should filter by scope' do
      params = { scope: 'authored', state: 'opened' }
      merge_requests = MergeRequestsFinder.new(user, params).execute
      expect(merge_requests.size).to eq(2)
    end

    it 'should filter by project' do
      params = { project_id: project1.id, scope: 'authored', state: 'opened' }
      merge_requests = MergeRequestsFinder.new(user, params).execute
      expect(merge_requests.size).to eq(1)
    end

    it 'should ignore sorting by weight' do
      params = { project_id: project1.id, scope: 'authored', state: 'opened', weight: Issue::WEIGHT_ANY }
      merge_requests = MergeRequestsFinder.new(user, params).execute
      expect(merge_requests.size).to eq(1)
    end
  end
end
