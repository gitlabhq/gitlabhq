# frozen_string_literal: true

RSpec.describe Gitlab::Database::LockRetries do
  it "has a version number" do
    expect(Gitlab::Database::LockRetries::VERSION).not_to be nil
  end

  it "can use database" do
    expect(ApplicationRecord.connection.select_value('SELECT 42')).to eq(42)
  end
end
