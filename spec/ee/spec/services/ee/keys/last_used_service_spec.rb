require 'spec_helper'

describe Keys::LastUsedService do
  it 'does not run on read-only GitLab instances', :clean_gitlab_redis_shared_state do
    key = create(:key, last_used_at: 1.year.ago)
    original_time = key.last_used_at

    allow(::Gitlab::Database).to receive(:read_only?).and_return(true)
    described_class.new(key).execute

    expect(key.reload.last_used_at).to be_like_time(original_time)
  end
end
