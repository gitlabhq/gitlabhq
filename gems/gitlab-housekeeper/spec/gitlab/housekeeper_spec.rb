# frozen_string_literal: true

RSpec.describe Gitlab::Housekeeper do
  it "has a version number" do
    expect(Gitlab::Housekeeper::VERSION).not_to be nil
  end
end
