require 'spec_helper'

describe Groups::AnalyticsController do
  let(:user) { create(:user) }
  let(:user2) { create(:user) }
  let(:user3) { create(:user) }
  let(:group) { create(:group) }
  let(:project) { create(:project, :repository, group: group) }
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
    PushEventPayloadService.new(event, push_data).execute
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

  it 'returns 404 when feature is not available and we dont show promotions' do
    stub_licensed_features(contribution_analytics: false)

    get :show, group_id: group.path

    expect(response).to have_gitlab_http_status(404)
  end

  context 'unlicensed but we show promotions' do
    before do
      allow(License).to receive(:current).and_return(nil)
      allow(LicenseHelper).to receive(:show_promotions?).and_return(true)
      stub_application_setting(check_namespace_plan: false)
    end

    it 'returns page when feature is not available and we show promotions' do
      stub_licensed_features(contribution_analytics: false)

      get :show, group_id: group.path

      expect(response).to have_gitlab_http_status(200)
    end
  end

  it 'sets instance variables properly', :aggregate_failures do
    get :show, group_id: group.path

    expect(response).to have_gitlab_http_status(200)

    expect(assigns[:users]).to match_array([user, user2, user3])
    expect(assigns[:events].length).to eq(6)
    stats = assigns[:stats]

    # NOTE: The array ordering matters! The view references them all by index
    expect(stats[:merge_requests_created]).to eq([0, 1, 1])
    expect(stats[:issues_closed]).to eq([1, 1, 0])
    expect(stats[:push]).to eq([1, 0, 1])
  end

  it "returns member contributions JSON when format is JSON" do
    get :show, group_id: group.path, format: :json

    expect(json_response.length).to eq(3)

    first_user = json_response.at(0)
    expect(first_user["username"]).to eq(user.username)
    expect(first_user["user_web_url"]).to eq("/#{user.username}")
    expect(first_user["fullname"]).to eq(user.name)
    expect(first_user["push"]).to eq(1)
    expect(first_user["issues_created"]).to eq(0)
    expect(first_user["issues_closed"]).to eq(1)
    expect(first_user["merge_requests_created"]).to eq(0)
    expect(first_user["merge_requests_merged"]).to eq(0)
    expect(first_user["total_events"]).to eq(2)
  end

  it 'does not cause N+1 queries when the format is JSON' do
    control_count = ActiveRecord::QueryRecorder.new do
      get :show, group_id: group.path, format: :json
    end

    controller.instance_variable_set(:@group, nil)
    user4 = create(:user)
    group.add_user(user4, GroupMember::DEVELOPER)

    expect { get :show, group_id: group.path, format: :json }
      .not_to exceed_query_limit(control_count)
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

  describe 'GET #index' do
    subject { get :show, group_id: group.to_param }

    it_behaves_like 'disabled when using an external authorization service'
  end
end
