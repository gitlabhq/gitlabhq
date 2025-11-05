# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::CommitStatusesFinder, '#execute', feature_category: :source_code_management do
  let_it_be(:project) { create(:project, :public, :repository) }
  let_it_be(:release) { create(:release, project: project) }
  let_it_be(:user) { create(:user) }

  let_it_be(:tags) { project.repository.tags }
  let_it_be(:branches) { project.repository.local_branches }
  let_it_be(:refs) { tags + branches }

  let(:ref_type) { nil }

  subject(:execute) { described_class.new(project, project.repository, user, refs, ref_type: ref_type).execute }

  before_all do
    project.add_developer(user)
  end

  context 'when no pipelines exist' do
    it 'returns nil' do
      expect(execute).to be_blank
    end
  end

  context 'when pipelines exist', :aggregate_failures do
    let_it_be(:heads_wip_pipeline) do
      ref = branches.find { |branch| branch.name == 'wip' }
      create(
        :ci_pipeline, :success,
        project: project, user: user,
        ref: ref.name, sha: ref.dereferenced_target.sha
      )
    end

    let_it_be(:heads_master_pipeline_1) do
      ref = branches.find { |branch| branch.name == 'master' }
      create(
        :ci_pipeline, :running,
        project: project,
        ref: ref.name, sha: ref.dereferenced_target.sha
      )
    end

    let_it_be(:heads_master_pipeline_2) do
      ref = branches.find { |branch| branch.name == 'master' }
      create(
        :ci_pipeline, :success,
        project: project, user: user,
        ref: ref.name, sha: ref.dereferenced_target.sha
      )
    end

    let_it_be(:tags_v1_1_0_pipeline) do
      ref = tags.find { |tag| tag.name == 'v1.1.0' }
      create(
        :ci_pipeline, :tag, :running,
        project: project,
        ref: ref.name, sha: ref.dereferenced_target.sha
      )
    end

    let_it_be(:heads_v1_1_0_pipeline) do
      ref = branches.find { |branch| branch.name == 'v1.1.0' }
      create(
        :ci_pipeline, :success,
        project: project,
        ref: ref.name, sha: ref.dereferenced_target.sha
      )
    end

    let_it_be(:tags_v1_0_0_pipeline_1) do
      ref = tags.find { |tag| tag.name == 'v1.0.0' }
      create(
        :ci_pipeline, :tag, :running,
        project: project,
        ref: ref.name, sha: ref.dereferenced_target.sha
      )
    end

    let_it_be(:tags_v1_0_0_pipeline_2) do
      ref = tags.find { |tag| tag.name == 'v1.0.0' }
      create(
        :ci_pipeline, :tag, :success,
        project: project,
        ref: ref.name, sha: ref.dereferenced_target.sha
      )
    end

    let(:pipeline_for_wip_status) { execute['wip']&.subject }
    let(:pipeline_for_master_status) { execute['master']&.subject }
    let(:pipeline_for_v1_1_0_status) { execute['v1.1.0']&.subject }
    let(:pipeline_for_v1_0_0_status) { execute['v1.0.0']&.subject }

    context 'when ref_type is nil' do
      it 'returns the statuses from the newest matching branch and tag pipelines' do
        expect(pipeline_for_wip_status).to eq(heads_wip_pipeline)
        expect(pipeline_for_master_status).to eq(heads_master_pipeline_2)
        expect(pipeline_for_v1_1_0_status).to eq(heads_v1_1_0_pipeline)
        expect(pipeline_for_v1_0_0_status).to eq(tags_v1_0_0_pipeline_2)
      end
    end

    context 'when ref_type is :tags' do
      let(:ref_type) { :tags }

      it 'returns the latest statuses from the newest matching tags pipelines' do
        expect(pipeline_for_wip_status).to be_nil
        expect(pipeline_for_master_status).to be_nil
        expect(pipeline_for_v1_1_0_status).to eq(tags_v1_1_0_pipeline)
        expect(pipeline_for_v1_0_0_status).to eq(tags_v1_0_0_pipeline_2)
      end
    end

    context 'when ref_type is :heads' do
      let(:ref_type) { :heads }

      it 'returns the latest statuses from the newest matching branch pipelines' do
        expect(pipeline_for_wip_status).to eq(heads_wip_pipeline)
        expect(pipeline_for_master_status).to eq(heads_master_pipeline_2)
        expect(pipeline_for_v1_1_0_status).to eq(heads_v1_1_0_pipeline)
        expect(pipeline_for_v1_0_0_status).to be_nil
      end
    end

    describe 'CI pipeline visiblity' do
      shared_examples 'returns something' do
        it { is_expected.not_to be_blank }
      end

      shared_examples 'returns a blank hash' do
        it { is_expected.to eq({}) }
      end

      context 'when everyone can view the pipelines' do
        it_behaves_like 'returns something'
      end

      context 'when builds are private' do
        let_it_be(:project) { create(:project, :repository, builds_access_level: ProjectFeature::PRIVATE) }

        before_all do
          create(
            :ci_pipeline, :tag, :running,
            project: project,
            ref: 'v1.1.0', sha: project.commit('v1.1.0').sha
          )
        end

        context 'and user is a member of the project' do
          before_all do
            project.add_developer(user)
          end

          it_behaves_like 'returns something'
        end

        context 'and user is not a member of the project' do
          it_behaves_like 'returns a blank hash'
        end
      end

      context 'when not a member of a private project' do
        let_it_be(:project) { create(:project, :private, :repository) }

        subject(:execute) { described_class.new(project, project.repository, user, refs).execute }

        before_all do
          create(
            :ci_pipeline, :tag, :running,
            project: project,
            ref: 'v1.1.0', sha: project.commit('v1.1.0').sha
          )
        end

        context 'and user is a member of the project' do
          before_all do
            project.add_developer(user)
          end

          it_behaves_like 'returns something'
        end

        context 'and user is not a member of the project' do
          it_behaves_like 'returns a blank hash'
        end
      end
    end
  end
end
