# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SearchHelper, 'search navigation (JavaScript fixtures)', type: :helper, feature_category: :global_search do
  include ApplicationHelper
  include JavaScriptFixturesHelpers

  let_it_be(:current_user) { create(:user) }
  let_it_be(:project) { create(:project) }
  let_it_be(:group) { create(:group) }

  let(:objectives_type) { 'objective' }
  let(:issues_scope) { 'issues' }
  let(:mock_params) do
    ActionController::Parameters.new({
      type: objectives_type
    })
  end

  let(:navigation) do
    Gitlab::Json.parse(helper.search_navigation_json)
  end

  let(:response) do
    obj = navigation.to_json
    def obj.successful?
      true
    end
    obj
  end

  before do
    allow(helper).to receive_messages(current_user: current_user, can?: true)
  end

  it 'search_navigation/root_level_active.json' do
    merge_requests_scope = 'merge_requests'
    allow(helper).to receive(:scope).and_return(merge_requests_scope)
    instance_variable_set(:@scope, merge_requests_scope)
    expect(response).to be_successful
  end

  it 'search_navigation/sub_item_active.json' do
    allow(helper).to receive_messages(scope: issues_scope, params: mock_params)
    instance_variable_set(:@scope, issues_scope)

    expect(response).to be_successful
  end

  it 'search_navigation/no_active_items.json' do
    expect(response).to be_successful
  end

  context 'with partial navigation' do
    let(:navigation) do
      full_navigation = Gitlab::Json.parse(helper.search_navigation_json)
      full_navigation['issues']['sub_items']
    end

    it 'search_navigation/partial_navigation_active.json' do
      allow(helper).to receive_messages(scope: issues_scope, params: mock_params)
      instance_variable_set(:@scope, issues_scope)

      expect(response).to be_successful
    end
  end
end
