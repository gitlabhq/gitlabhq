# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::PipelinesHelper do
  include Devise::Test::ControllerHelpers

  describe 'pipeline_warnings' do
    let(:pipeline) { double(:pipeline, warning_messages: warning_messages) }

    subject { helper.pipeline_warnings(pipeline) }

    context 'when pipeline has no warnings' do
      let(:warning_messages) { [] }

      it 'is empty' do
        expect(subject).to be_nil
      end
    end

    context 'when pipeline has warnings' do
      let(:warning_messages) { [double(content: 'Warning 1'), double(content: 'Warning 2')] }

      it 'returns a warning callout box' do
        expect(subject).to have_css 'div.bs-callout-warning'
        expect(subject).to include '2 warning(s) found:'
      end

      it 'lists the the warnings' do
        expect(subject).to include 'Warning 1'
        expect(subject).to include 'Warning 2'
      end
    end
  end

  describe 'warning_header' do
    subject { helper.warning_header(count) }

    context 'when warnings are more than max cap' do
      let(:count) { 30 }

      it 'returns 30 warning(s) found: showing first 25' do
        expect(subject).to eq('30 warning(s) found: showing first 25')
      end
    end

    context 'when warnings are less than max cap' do
      let(:count) { 15 }

      it 'returns 15 warning(s) found' do
        expect(subject).to eq('15 warning(s) found:')
      end
    end
  end

  describe 'has_gitlab_ci?' do
    using RSpec::Parameterized::TableSyntax

    subject(:has_gitlab_ci?) { helper.has_gitlab_ci?(project) }

    let(:project) { double(:project, has_ci?: has_ci?, builds_enabled?: builds_enabled?) }

    where(:builds_enabled?, :has_ci?, :result) do
      true                | true    | true
      true                | false   | false
      false               | true    | false
      false               | false   | false
    end

    with_them do
      it { expect(has_gitlab_ci?).to eq(result) }
    end
  end

  describe 'has_pipeline_badges?' do
    let(:pipeline) { create(:ci_empty_pipeline) }

    subject { helper.has_pipeline_badges?(pipeline) }

    context 'when pipeline has a badge' do
      before do
        pipeline.drop!(:config_error)
      end

      it 'shows pipeline badges' do
        expect(subject).to eq(true)
      end
    end

    context 'when pipeline has no badges' do
      it 'shows pipeline badges' do
        expect(subject).to eq(false)
      end
    end
  end

  describe '#pipelines_list_data' do
    let_it_be(:project) { create(:project) }

    subject(:data) { helper.pipelines_list_data(project, 'list_url') }

    before do
      allow(helper).to receive(:can?).and_return(true)
    end

    it 'has the expected keys' do
      expect(subject.keys).to match_array([:endpoint,
                                           :project_id,
                                           :default_branch_name,
                                           :params,
                                           :artifacts_endpoint,
                                           :artifacts_endpoint_placeholder,
                                           :pipeline_schedule_url,
                                           :empty_state_svg_path,
                                           :error_state_svg_path,
                                           :no_pipelines_svg_path,
                                           :can_create_pipeline,
                                           :new_pipeline_path,
                                           :ci_lint_path,
                                           :reset_cache_path,
                                           :has_gitlab_ci,
                                           :pipeline_editor_path,
                                           :suggested_ci_templates,
                                           :ci_runner_settings_path])
    end

    describe 'the `any_runners_available` attribute' do
      subject { data[:any_runners_available] }

      context 'when the `runners_availability_section` experiment variant is control' do
        before do
          stub_experiments(runners_availability_section: :control)
        end

        it { is_expected.to be_nil }
      end

      context 'when the `runners_availability_section` experiment variant is candidate' do
        before do
          stub_experiments(runners_availability_section: :candidate)
        end

        context 'when there are no runners' do
          it { is_expected.to eq('false') }
        end

        context 'when there are runners' do
          let!(:runner) { create(:ci_runner, :project, projects: [project]) }

          it { is_expected.to eq('true') }
        end
      end
    end
  end
end
