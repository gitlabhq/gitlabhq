# frozen_string_literal: true

require 'spec_helper'

# `ai_usage_events` now scopes by the org-prefixed `traversal_path`, but it keeps `namespace_path`
# because five materialized views forward that column into tables which have not migrated yet.
# Those tables must keep receiving the legacy format until https://gitlab.com/gitlab-org/gitlab/-/issues/603734
# reaches them -- writing an org-prefixed path into them would silently corrupt every namespace
# lookup that still expects `{root_ns}/.../{leaf}/`.
RSpec.describe 'ai_usage_events downstream containment', :click_house, feature_category: :value_stream_management do
  let(:connection) { ::ClickHouse::Connection.new(:main) }

  let(:legacy_path) { '9/42/' }
  let(:org_scoped_path) { '7/9/42/' }

  # Each event routes to a different subset of the downstream views. The ids are spelled out rather
  # than read from Gitlab::Tracking::AiTracking, which is EE-only while these views are not, and
  # they match the literals the view definitions filter on.
  let(:code_suggestion_event) { 2 }  # code_suggestion_shown_in_ide
  let(:duo_chat_event) { 6 }         # request_duo_chat_response
  let(:agent_platform_event) { 8 }   # agent_platform_session_created

  def insert_event(event, extras)
    connection.execute(<<~SQL)
      INSERT INTO ai_usage_events (user_id, event, timestamp, namespace_path, traversal_path, extras)
      VALUES (
        1, #{event}, toDateTime64('2026-06-01 10:00:00', 6, 'UTC'),
        '#{legacy_path}', '#{org_scoped_path}', '#{extras}'
      )
    SQL
  end

  def paths_in(table)
    connection.select("SELECT DISTINCT namespace_path FROM #{table}").pluck('namespace_path')
  end

  before do
    insert_event(code_suggestion_event, '{"unique_tracking_id":"abc","language":"ruby"}')
    insert_event(duo_chat_event, '{}')
    insert_event(agent_platform_event, '{"project_id":5,"session_id":77,"flow_type":"chat","environment":""}')
  end

  it 'scopes the source table by the org-prefixed path' do
    expect(paths_in('ai_usage_events')).to contain_exactly(legacy_path)

    traversal_paths = connection.select('SELECT DISTINCT traversal_path FROM ai_usage_events').pluck('traversal_path')
    expect(traversal_paths).to contain_exactly(org_scoped_path)
  end

  where(:downstream_table) do
    %w[
      ai_usage_events_daily
      ai_code_suggestions
      code_suggestion_events_daily
      duo_chat_events_daily
      agent_platform_sessions
    ]
  end

  with_them do
    it 'still receives the legacy path format' do
      expect(paths_in(downstream_table)).to contain_exactly(legacy_path)
    end
  end
end
