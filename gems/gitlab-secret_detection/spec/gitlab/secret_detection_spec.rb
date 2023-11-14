# frozen_string_literal: true

RSpec.describe Gitlab::SecretDetection do
  it "has a version number" do
    expect(Gitlab::SecretDetection::VERSION).not_to be_nil
  end
end
