# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SecurityReportsMrWidgetPromptExperiment do
  it "defines a control and candidate" do
    expect(subject.behaviors.keys).to match_array(%w[control candidate])
  end

  it "publishes to the database" do
    expect(subject).to receive(:publish_to_database)

    subject.publish
  end
end
