# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::CommitStatusesFinder, '#execute' do
  let_it_be(:project) { create(:project, :public, :repository) }
  let_it_be(:release) { create(:release, project: project) }
  let_it_be(:user) { create(:user) }

  context 'tag refs' do
    let_it_be(:tags) { TagsFinder.new(project.repository, {}).execute }

    let(:subject) { described_class.new(project, project.repository, user, tags).execute }

    context 'no pipelines' do
      it 'returns nil' do
        expect(subject).to be_blank
      end
    end

    context 'when multiple tags exist' do
      before do
        create(:ci_pipeline,
          project: project,
          ref: 'v1.1.0',
          sha: project.commit('v1.1.0').sha,
          status: :running)
        create(:ci_pipeline,
          project: project,
          ref: 'v1.0.0',
          sha: project.commit('v1.0.0').sha,
          status: :success)
      end

      it 'all relevant commit statuses are received' do
        expect(subject['v1.1.0'].group).to eq("running")
        expect(subject['v1.0.0'].group).to eq("success")
      end
    end

    context 'when a tag has multiple pipelines' do
      before do
        create(:ci_pipeline,
          project: project,
          ref: 'v1.0.0',
          sha: project.commit('v1.0.0').sha,
          status: :running,
          created_at: 6.months.ago)
        create(:ci_pipeline,
          project: project,
          ref: 'v1.0.0',
          sha: project.commit('v1.0.0').sha,
          status: :success,
          created_at: 2.months.ago)
      end

      it 'chooses the latest to determine status' do
        expect(subject['v1.0.0'].group).to eq("success")
      end
    end
  end

  context 'branch refs' do
    let(:subject) { described_class.new(project, project.repository, user, branches).execute }

    before do
      project.add_developer(user)
    end

    context 'no pipelines' do
      let(:branches) { BranchesFinder.new(project.repository, {}).execute }

      it 'returns nil' do
        expect(subject).to be_blank
      end
    end

    context 'when a branch has multiple pipelines' do
      let(:branches) { BranchesFinder.new(project.repository, {}).execute }

      before do
        sha = project.repository.create_file(user, generate(:branch), 'content', message: 'message', branch_name: 'master')
        create(:ci_pipeline,
          project: project,
          user: user,
          ref: "master",
          sha: sha,
          status: :running,
          created_at: 6.months.ago)
        create(:ci_pipeline,
          project: project,
          user: user,
          ref: "master",
          sha: sha,
          status: :success,
          created_at: 2.months.ago)
      end

      it 'chooses the latest to determine status' do
        expect(subject["master"].group).to eq("success")
      end
    end

    context 'when multiple branches exist' do
      let(:branches) { BranchesFinder.new(project.repository, {}).execute }

      before do
        master_sha = project.repository.create_file(user, generate(:branch), 'content', message: 'message', branch_name: 'master')
        create(:ci_pipeline,
          project: project,
          user: user,
          ref: "master",
          sha: master_sha,
          status: :running,
          created_at: 6.months.ago)
        test_sha = project.repository.create_file(user, generate(:branch), 'content', message: 'message', branch_name: 'test')
        create(:ci_pipeline,
          project: project,
          user: user,
          ref: "test",
          sha: test_sha,
          status: :success,
          created_at: 2.months.ago)
      end

      it 'all relevant commit statuses are received' do
        expect(subject["master"].group).to eq("running")
        expect(subject["test"].group).to eq("success")
      end
    end
  end

  context 'CI pipelines visible to' do
    let_it_be(:tags) { TagsFinder.new(project.repository, {}).execute }

    let(:subject) { described_class.new(project, project.repository, user, tags).execute }

    before do
      create(:ci_pipeline,
        project: project,
        ref: 'v1.1.0',
        sha: project.commit('v1.1.0').sha,
        status: :running)
    end

    context 'everyone' do
      it 'returns something' do
        expect(subject).not_to be_blank
      end
    end

    context 'project members only' do
      before do
        project.project_feature.update!(builds_access_level: ProjectFeature::PRIVATE)
      end

      it 'returns a blank hash' do
        expect(subject).to eq({})
      end
    end

    context 'when not a member of a private project' do
      let(:private_project) { create(:project, :private, :repository) }
      let(:private_tags) { TagsFinder.new(private_tags.repository, {}).execute }
      let(:private_subject) { described_class.new(private_project, private_project.repository, user, tags).execute }

      before do
        create(:ci_pipeline,
          project: private_project,
          ref: 'v1.1.0',
          sha: private_project.commit('v1.1.0').sha,
          status: :running)
      end

      it 'returns a blank hash' do
        expect(private_subject).to eq({})
      end
    end
  end
end
