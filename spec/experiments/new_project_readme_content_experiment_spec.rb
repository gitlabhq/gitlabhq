# frozen_string_literal: true

require 'spec_helper'

RSpec.describe NewProjectReadmeContentExperiment, :experiment do
  subject { described_class.new(namespace: project.namespace) }

  let(:project) { create(:project, name: 'Experimental', description: 'An experiment project') }

  it "renders the basic template" do
    expect(subject.run_with(project)).to eq(<<~MARKDOWN.strip)
      # Experimental

      An experiment project
    MARKDOWN
  end

  it "renders the advanced template" do
    expect(subject.run_with(project, variant: :advanced)).to include(<<~MARKDOWN.strip)
      # Experimental

      An experiment project

      ## Getting started
    MARKDOWN
  end
end
