# frozen_string_literal: true

RSpec.describe ActiveRecord::GitlabPatches do
  it "has a version number" do
    expect(described_class::Version::VERSION).not_to be nil
  end
end
