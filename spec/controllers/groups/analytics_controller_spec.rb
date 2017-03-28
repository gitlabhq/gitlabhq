require 'spec_helper'

describe Groups::AnalyticsController do
  let(:user) { create(:user) }
  let(:user2) { create(:user) }
  let(:user3) { create(:user) }
  let(:group) { create(:group) }
  let(:project) { create(:project, group: group) }
  let(:issue) { create(:issue, project: project) }
  let(:merge_request) { create(:merge_request, :simple, source_project: project) }
  let(:push_data) { Gitlab::DataBuilder::Push.build_sample(project, user) }

  def create_event(author, project, target, action)
    Event.create!(
      project: project,
      action: action,
      target: target,
      author: author,
      created_at: Time.now)
  end

  def create_push_event(author, project)
    event = create_event(author, project, nil, Event::PUSHED)
    event.data = push_data
    event.save
  end

  before do
    group.add_owner(user)
    group.add_user(user2, GroupMember::DEVELOPER)
    group.add_user(user3, GroupMember::MASTER)
    sign_in(user)

    create_event(user, project, issue, Event::CLOSED)
    create_event(user2, project, issue, Event::CLOSED)
    create_event(user2, project, merge_request, Event::CREATED)
    create_event(user3, project, merge_request, Event::CREATED)
    create_push_event(user, project)
    create_push_event(user3, project)
  end

  it 'sets instance variables properly' do
    get :show, group_id: group.path

    expect(controller.instance_variable_get(:@users)).to match_array([user, user2, user3])
    expect(controller.instance_variable_get(:@events).length).to eq(6)
    stats = controller.instance_variable_get(:@stats)
    expect(stats[:total_events]).to eq([2, 2, 2])
    expect(stats[:merge_requests_merged]).to eq([0, 0, 0])
    expect(stats[:merge_requests_created]).to eq([1, 1, 0])
    expect(stats[:issues_closed]).to eq([0, 1, 1])
    expect(stats[:push]).to eq([1, 0, 1])
  end

  describe 'with views' do
    render_views

    it 'avoids a N+1 query in #show' do
      control_count = ActiveRecord::QueryRecorder.new { get :show, group_id: group.path }.count

      # Clear out controller state to force a refresh of the group
      controller.instance_variable_set(:@group, nil)
      user4 = create(:user)
      group.add_user(user4, GroupMember::DEVELOPER)

      expect { get :show, group_id: group.path }.not_to exceed_query_limit(control_count)
    end
  end
end
