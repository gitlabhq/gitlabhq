# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::Ci::JobsResolver do
  include GraphqlHelpers

  let_it_be(:project) { create(:project, :repository, :public) }
  let_it_be(:pipeline) { create(:ci_pipeline, project: project) }

  before_all do
    create(:ci_build, name: 'Normal job', pipeline: pipeline)
    create(:ci_build, :sast, name: 'DAST job', pipeline: pipeline)
    create(:ci_build, :dast, name: 'SAST job', pipeline: pipeline)
    create(:ci_build, :container_scanning, name: 'Container scanning job', pipeline: pipeline)
    create(:ci_build, name: 'Job with tags', pipeline: pipeline, tag_list: ['review'])
  end

  describe '#resolve' do
    context 'when security_report_types is empty' do
      it "returns all of the pipeline's jobs" do
        jobs = resolve(described_class, obj: pipeline)

        expect(jobs).to contain_exactly(
          have_attributes(name: 'Normal job'),
          have_attributes(name: 'DAST job'),
          have_attributes(name: 'SAST job'),
          have_attributes(name: 'Container scanning job'),
          have_attributes(name: 'Job with tags')
        )
      end
    end

    context 'when security_report_types is present' do
      it "returns the pipeline's jobs with the given security report types" do
        report_types = [
          ::Types::Security::ReportTypeEnum.values['SAST'].value,
          ::Types::Security::ReportTypeEnum.values['DAST'].value
        ]
        jobs = resolve(described_class, obj: pipeline, args: { security_report_types: report_types })

        expect(jobs).to contain_exactly(
          have_attributes(name: 'DAST job'),
          have_attributes(name: 'SAST job')
        )
      end
    end

    context 'when a job has tags' do
      it "returns jobs with tags when applicable" do
        jobs = resolve(described_class, obj: pipeline)
        expect(jobs).to contain_exactly(
          have_attributes(tag_list: []),
          have_attributes(tag_list: []),
          have_attributes(tag_list: []),
          have_attributes(tag_list: []),
          have_attributes(tag_list: ['review'])
        )
      end
    end
  end
end
