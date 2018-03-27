require 'spec_helper'

describe Gitlab::Ci::Build::Policy::Variables do
  let(:project) { create(:project) }

  let(:pipeline) do
    build(:ci_empty_pipeline, project: project, ref: 'master')
  end

  let(:ci_build) do
    build(:ci_build, pipeline: pipeline,
                     project: project,
                     ref: 'master',
                     stage: 'review',
                     environment: 'test/$CI_JOB_STAGE/1')
  end

  let(:seed) { double('build seed', to_resource: ci_build) }

  describe '#satisfied_by?' do
    context 'when using project secret variables in environment scope' do
      before do
        create(:ci_variable, project: project,
                             key: 'SCOPED_VARIABLE',
                             value: 'my-value-1')

        create(:ci_variable, project: project,
                             key: 'SCOPED_VARIABLE',
                             value: 'my-value-2',
                             environment_scope: 'test/review/*')
      end

      context 'when environment scope variables feature is enabled' do
        before do
          stub_licensed_features(variable_environment_scope: true)
        end

        it 'is satisfied by  scoped variable match' do
          policy = described_class.new(['$SCOPED_VARIABLE == "my-value-2"'])

          expect(policy).to be_satisfied_by(pipeline, seed)
        end

        it 'is not satisfied when matching against overridden variable' do
          policy = described_class.new(['$SCOPED_VARIABLE == "my-value-1"'])

          expect(policy).not_to be_satisfied_by(pipeline, seed)
        end
      end

      context 'when environment scope variables feature is disabled' do
        before do
          stub_licensed_features(variable_environment_scope: false)
        end

        it 'is not satisfied by scoped variable match' do
          policy = described_class.new(['$SCOPED_VARIABLE == "my-value-2"'])

          expect(policy).not_to be_satisfied_by(pipeline, seed)
        end

        it 'is satisfied when matching against unscoped variable' do
          policy = described_class.new(['$SCOPED_VARIABLE == "my-value-1"'])

          expect(policy).to be_satisfied_by(pipeline, seed)
        end
      end
    end
  end
end
