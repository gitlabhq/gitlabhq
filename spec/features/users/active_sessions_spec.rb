# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Active user sessions', :clean_gitlab_redis_sessions, feature_category: :system_access do
  it 'successful login adds a new active user login', :js do
    user = create(:user)

    now = Time.zone.now.change(usec: 0)
    travel_to(now) do
      gitlab_sign_in(user)
      expect(page).to have_current_path root_path, ignore_query: true

      sessions = ActiveSession.list(user)
      expect(sessions.count).to eq 1
      gitlab_sign_out
    end

    # refresh the current page updates the updated_at
    travel_to(now + 1.minute) do
      gitlab_sign_in(user)

      visit current_path

      sessions = ActiveSession.list(user)
      expect(sessions.first).to have_attributes(
        created_at: now,
        updated_at: now + 1.minute
      )
    end
  end

  it 'successful login cleans up obsolete entries' do
    user = create(:user)

    Gitlab::Redis::Sessions.with do |redis|
      redis.sadd?("session:lookup:user:gitlab:#{user.id}", '59822c7d9fcdfa03725eff41782ad97d')
    end

    gitlab_sign_in(user)

    Gitlab::Redis::Sessions.with do |redis|
      expect(redis.smembers("session:lookup:user:gitlab:#{user.id}")).not_to include '59822c7d9fcdfa03725eff41782ad97d'
    end
  end

  it 'sessionless login does not clean up obsolete entries' do
    user = create(:user)
    personal_access_token = create(:personal_access_token, user: user)

    Gitlab::Redis::Sessions.with do |redis|
      redis.sadd?("session:lookup:user:gitlab:#{user.id}", '59822c7d9fcdfa03725eff41782ad97d')
    end

    visit user_path(user, :atom, private_token: personal_access_token.token)
    expect(page.status_code).to eq 200

    Gitlab::Redis::Sessions.with do |redis|
      expect(redis.smembers("session:lookup:user:gitlab:#{user.id}")).to include '59822c7d9fcdfa03725eff41782ad97d'
    end
  end

  it 'logout deletes the active user login', :js do
    user = create(:user)
    gitlab_sign_in(user)
    expect(page).to have_current_path root_path, ignore_query: true

    expect(ActiveSession.list(user).count).to eq 1

    gitlab_sign_out
    expect(page).to have_current_path new_user_session_path, ignore_query: true

    expect(ActiveSession.list(user)).to be_empty
  end
end
