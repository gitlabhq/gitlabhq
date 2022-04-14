# frozen_string_literal: true

require 'spec_helper'

RSpec.describe IosSpecificTemplatesExperiment do
  subject do
    described_class.new(actor: user, project: project) do |e|
      e.candidate { true }
    end.run
  end

  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :auto_devops_disabled) }

  let!(:project_setting) { create(:project_setting, project: project, target_platforms: target_platforms) }
  let(:target_platforms) { %w(ios) }

  before do
    stub_experiments(ios_specific_templates: :candidate)
    project.add_developer(user) if user
  end

  it { is_expected.to be true }

  describe 'skipping the experiment' do
    context 'no actor' do
      let_it_be(:user) { nil }

      it { is_expected.to be_falsey }
    end

    context 'actor cannot create pipelines' do
      before do
        project.add_guest(user)
      end

      it { is_expected.to be_falsey }
    end

    context 'targeting a non iOS platform' do
      let(:target_platforms) { [] }

      it { is_expected.to be_falsey }
    end

    context 'project has a ci.yaml file' do
      before do
        allow(project).to receive(:has_ci?).and_return(true)
      end

      it { is_expected.to be_falsey }
    end

    context 'project has pipelines' do
      before do
        create(:ci_pipeline, project: project)
      end

      it { is_expected.to be_falsey }
    end
  end
end
