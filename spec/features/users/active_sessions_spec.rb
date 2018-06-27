require 'spec_helper'

feature 'Active user sessions', :clean_gitlab_redis_shared_state do
  scenario 'Successful login adds a new active user login' do
    now = Time.zone.parse('2018-03-12 09:06')
    Timecop.freeze(now) do
      user = create(:user)
      gitlab_sign_in(user)
      expect(current_path).to eq root_path

      sessions = ActiveSession.list(user)
      expect(sessions.count).to eq 1

      # refresh the current page updates the updated_at
      Timecop.freeze(now + 1.minute) do
        visit current_path

        sessions = ActiveSession.list(user)
        expect(sessions.first).to have_attributes(
          created_at: Time.zone.parse('2018-03-12 09:06'),
          updated_at: Time.zone.parse('2018-03-12 09:07')
        )
      end
    end
  end

  scenario 'Successful login cleans up obsolete entries' do
    user = create(:user)

    Gitlab::Redis::SharedState.with do |redis|
      redis.sadd("session:lookup:user:gitlab:#{user.id}", '59822c7d9fcdfa03725eff41782ad97d')
    end

    gitlab_sign_in(user)

    Gitlab::Redis::SharedState.with do |redis|
      expect(redis.smembers("session:lookup:user:gitlab:#{user.id}")).not_to include '59822c7d9fcdfa03725eff41782ad97d'
    end
  end

  scenario 'Sessionless login does not clean up obsolete entries' do
    user = create(:user)
    personal_access_token = create(:personal_access_token, user: user)

    Gitlab::Redis::SharedState.with do |redis|
      redis.sadd("session:lookup:user:gitlab:#{user.id}", '59822c7d9fcdfa03725eff41782ad97d')
    end

    visit user_path(user, :atom, private_token: personal_access_token.token)
    expect(page.status_code).to eq 200

    Gitlab::Redis::SharedState.with do |redis|
      expect(redis.smembers("session:lookup:user:gitlab:#{user.id}")).to include '59822c7d9fcdfa03725eff41782ad97d'
    end
  end

  scenario 'Logout deletes the active user login' do
    user = create(:user)
    gitlab_sign_in(user)
    expect(current_path).to eq root_path

    expect(ActiveSession.list(user).count).to eq 1

    gitlab_sign_out
    expect(current_path).to eq new_user_session_path

    expect(ActiveSession.list(user)).to be_empty
  end
end
