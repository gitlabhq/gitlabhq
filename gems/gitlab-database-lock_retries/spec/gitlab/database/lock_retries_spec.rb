# frozen_string_literal: true

RSpec.describe Gitlab::Database::LockRetries do
  it "has a version number" do
    expect(Gitlab::Database::LockRetries::VERSION).not_to be nil
  end

  xit "does something useful"
end
