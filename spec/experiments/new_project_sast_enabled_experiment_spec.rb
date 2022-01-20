# frozen_string_literal: true

require 'spec_helper'

RSpec.describe NewProjectSastEnabledExperiment do
  it "defines the expected behaviors and variants" do
    expect(subject.variant_names).to match_array([
      :candidate,
      :free_indicator,
      :unchecked_candidate,
      :unchecked_free_indicator
    ])
  end

  it "publishes to the database" do
    expect(subject).to receive(:publish_to_database)

    subject.publish
  end
end
