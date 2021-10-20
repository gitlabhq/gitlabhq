# frozen_string_literal: true

require 'spec_helper'

RSpec.describe NewProjectSastEnabledExperiment do
  it "defines the expected behaviors and variants" do
    expect(subject.behaviors.keys).to match_array(%w[control candidate free_indicator])
  end

  it "publishes to the database" do
    expect(subject).to receive(:publish_to_database)

    subject.publish
  end
end
