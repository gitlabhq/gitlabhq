# frozen_string_literal: true

RSpec.describe Gitlab::Schema::Validation do
  it "has a version number" do
    expect(Gitlab::Schema::Validation::Version::VERSION).not_to be_nil
  end
end
