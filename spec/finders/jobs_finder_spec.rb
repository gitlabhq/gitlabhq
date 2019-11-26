# frozen_string_literal: true

require 'spec_helper'

describe JobsFinder, '#execute' do
  set(:user) { create(:user) }
  set(:admin) { create(:user, :admin) }
  set(:project) { create(:project, :private, public_builds: false) }
  set(:pipeline) { create(:ci_pipeline, project: project) }
  set(:job_1) { create(:ci_build) }
  set(:job_2) { create(:ci_build, :running) }
  set(:job_3) { create(:ci_build, :success, pipeline: pipeline) }

  let(:params) { {} }

  context 'no project' do
    subject { described_class.new(current_user: admin, params: params).execute }

    it 'returns all jobs' do
      expect(subject).to match_array([job_1, job_2, job_3])
    end

    context 'non admin user' do
      let(:admin) { user }

      it 'returns no jobs' do
        expect(subject).to be_empty
      end
    end

    context 'without user' do
      let(:admin) { nil }

      it 'returns no jobs' do
        expect(subject).to be_empty
      end
    end

    context 'scope is present' do
      let(:jobs) { [job_1, job_2, job_3] }

      where(:scope, :index) do
        [
          ['pending',  0],
          ['running',  1],
          ['finished', 2]
        ]
      end

      with_them do
        let(:params) { { scope: scope } }

        it { expect(subject).to match_array([jobs[index]]) }
      end
    end
  end

  context 'a project is present' do
    subject { described_class.new(current_user: user, project: project, params: params).execute }

    context 'user has access to the project' do
      before do
        project.add_maintainer(user)
      end

      it 'returns jobs for the specified project' do
        expect(subject).to match_array([job_3])
      end
    end

    context 'user has no access to project builds' do
      before do
        project.add_guest(user)
      end

      it 'returns no jobs' do
        expect(subject).to be_empty
      end
    end

    context 'without user' do
      let(:user) { nil }

      it 'returns no jobs' do
        expect(subject).to be_empty
      end
    end
  end
end
