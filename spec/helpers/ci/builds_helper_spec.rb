# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::BuildsHelper, feature_category: :continuous_integration do
  describe '#build_failed_issue_options' do
    subject { helper.build_failed_issue_options }

    it 'returns failed title and description' do
      project = assign_project
      ci_build = assign_build

      expect(subject).to eq(title: "Job Failed \##{ci_build.id}", description: project_job_url(project, ci_build))
    end
  end

  def assign_project
    build_stubbed(:project).tap do |project|
      assign(:project, project)
    end
  end

  def assign_build
    build_stubbed(:ci_build).tap do |ci_build|
      assign(:build, ci_build)
    end
  end
end
