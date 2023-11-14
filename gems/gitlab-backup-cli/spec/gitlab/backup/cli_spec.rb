# frozen_string_literal: true

RSpec.describe Gitlab::Backup::Cli do
  it "has a version number" do
    expect(Gitlab::Backup::Cli::VERSION).not_to be nil
  end
end
