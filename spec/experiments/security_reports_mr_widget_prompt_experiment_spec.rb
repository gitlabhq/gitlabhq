# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SecurityReportsMrWidgetPromptExperiment do
  it "defines a control and candidate" do
    expect(subject.behaviors.keys).to match_array(%w[control candidate])
  end
end
