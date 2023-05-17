# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::BuildsHelper do
  describe '#sidebar_build_class' do
    using RSpec::Parameterized::TableSyntax

    where(:build_id, :current_build_id, :retried, :expected_result) do
      1         | 1        | true  | 'active retried'
      1         | 1        | false | 'active'
      1         | 2        | false | ''
      1         | 2        | true  | 'retried'
    end

    let(:build) { instance_double(Ci::Build, retried?: retried, id: build_id) }
    let(:current_build) { instance_double(Ci::Build, retried?: true, id: current_build_id ) }

    subject { helper.sidebar_build_class(build, current_build) }

    with_them do
      it 'builds sidebar html class' do
        expect(subject).to eq(expected_result)
      end
    end
  end

  describe '#javascript_build_options' do
    subject { helper.javascript_build_options }

    it 'returns build options' do
      project = assign_project
      ci_build = assign_build

      expect(subject).to eq({
        page_path: project_job_path(project, ci_build),
        build_status: ci_build.status,
        build_stage: ci_build.stage_name,
        log_state: ''
      })
    end
  end

  describe '#build_failed_issue_options' do
    subject { helper.build_failed_issue_options }

    it 'returns failed title and description' do
      project = assign_project
      ci_build = assign_build

      expect(subject).to eq(title: "Job Failed \##{ci_build.id}", description: project_job_url(project, ci_build))
    end
  end

  def assign_project
    build(:project).tap do |project|
      assign(:project, project)
    end
  end

  def assign_build
    create(:ci_build).tap do |ci_build|
      assign(:build, ci_build)
    end
  end
end
