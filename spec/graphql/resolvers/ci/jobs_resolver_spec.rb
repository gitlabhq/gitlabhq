# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::Ci::JobsResolver do
  include GraphqlHelpers

  let_it_be(:pipeline) { create(:ci_pipeline) }

  before_all do
    create(:ci_build, name: 'Normal job', pipeline: pipeline)
    create(:ci_build, :sast, name: 'DAST job', pipeline: pipeline)
    create(:ci_build, :dast, name: 'SAST job', pipeline: pipeline)
    create(:ci_build, :container_scanning, name: 'Container scanning job', pipeline: pipeline)
  end

  describe '#resolve' do
    context 'when security_report_types is empty' do
      it "returns all of the pipeline's jobs" do
        jobs = resolve(described_class, obj: pipeline, args: {}, ctx: {})

        job_names = jobs.map(&:name)
        expect(job_names).to contain_exactly('Normal job', 'DAST job', 'SAST job', 'Container scanning job')
      end
    end

    context 'when security_report_types is present' do
      it "returns the pipeline's jobs with the given security report types" do
        report_types = [
          ::Types::Security::ReportTypeEnum.values['SAST'].value,
          ::Types::Security::ReportTypeEnum.values['DAST'].value
        ]
        jobs = resolve(described_class, obj: pipeline, args: { security_report_types: report_types }, ctx: {})

        job_names = jobs.map(&:name)
        expect(job_names).to contain_exactly('DAST job', 'SAST job')
      end
    end
  end
end
