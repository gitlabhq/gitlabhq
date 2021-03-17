# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Session TTLs', :clean_gitlab_redis_shared_state do
  it 'creates a session with a short TTL when login fails' do
    visit new_user_session_path
    # The session key only gets created after a post
    fill_in 'user_login', with: 'non-existant@gitlab.org'
    fill_in 'user_password', with: '12345678'
    click_button 'Sign in'

    expect(page).to have_content('Invalid login or password')

    expect_single_session_with_expiration(Settings.gitlab['unauthenticated_session_expire_delay'])
  end

  it 'increases the TTL when the login succeeds' do
    user = create(:user)
    gitlab_sign_in(user)

    expect(page).to have_content(user.name)

    expect_single_session_with_expiration(Settings.gitlab['session_expire_delay'] * 60)
  end

  def expect_single_session_with_expiration(expiration)
    session_keys = get_session_keys

    expect(session_keys.size).to eq(1)
    expect(get_ttl(session_keys.first)).to eq expiration
  end

  def get_session_keys
    Gitlab::Redis::SharedState.with { |redis| redis.scan_each(match: 'session:gitlab:*').to_a }
  end

  def get_ttl(key)
    Gitlab::Redis::SharedState.with { |redis| redis.ttl(key) }
  end
end
