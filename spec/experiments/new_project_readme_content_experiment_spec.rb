# frozen_string_literal: true

require 'spec_helper'

RSpec.describe NewProjectReadmeContentExperiment, :experiment do
  subject { described_class.new(namespace: project.namespace) }

  let(:project) { create(:project, name: 'Experimental', description: 'An experiment project') }

  it "renders the basic README" do
    expect(subject.run_with(project)).to eq(<<~MARKDOWN.strip)
      # Experimental

      An experiment project
    MARKDOWN
  end

  describe "the advanced variant" do
    let(:markdown) { subject.run_with(project, variant: :advanced) }
    let(:initial_url) { 'https://docs.gitlab.com/ee/user/project/repository/web_editor.html#create-a-file' }

    it "renders the project details" do
      expect(markdown).to include(<<~MARKDOWN.strip)
        # Experimental

        An experiment project

        ## Getting started
      MARKDOWN
    end

    it "renders redirect URLs" do
      expect(markdown).to include(Rails.application.routes.url_helpers.experiment_redirect_url(subject, initial_url))
    end
  end
end
