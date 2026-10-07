# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::CommitStatusesFinder, '#execute', feature_category: :source_code_management do
  let_it_be_with_reload(:project) { create(:project, :public, :repository) }
  let_it_be_with_reload(:release) { create(:release, project: project) }
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
    let(:sha_in_predicate) { /"p_ci_pipelines"\."sha" IN \(([^)]+)\)/ }

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

    def pipeline_lookup_query(recorder)
      recorder.log.find { |query| query.include?('DISTINCT ON(p_ci_pipelines.ref)') }
    end

    context 'when ref_type is nil' do
      it 'returns the statuses from the newest matching branch and tag pipelines' do
        expect(pipeline_for_wip_status).to eq(heads_wip_pipeline)
        expect(pipeline_for_master_status).to eq(heads_master_pipeline_2)
        expect(pipeline_for_v1_1_0_status).to eq(heads_v1_1_0_pipeline)
        expect(pipeline_for_v1_0_0_status).to eq(tags_v1_0_0_pipeline_2)
      end

      context 'when tag does not point to a commit' do
        let(:tags) do
          [Gitlab::Git::Tag.new(project.repository, { name: 'v1.0.0', target: 'commit_sha', target_commit: nil })]
        end

        let(:refs) { tags + branches }

        it 'skips pipelines for invalid tags' do
          expect(execute.keys).to match_array(['wip', 'master', 'v1.1.0'])

          expect(pipeline_for_wip_status).to eq(heads_wip_pipeline)
          expect(pipeline_for_master_status).to eq(heads_master_pipeline_2)
          expect(pipeline_for_v1_1_0_status).to eq(heads_v1_1_0_pipeline)
          expect(pipeline_for_v1_0_0_status).to be_nil
        end
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

      it 'filters the tag pipeline lookup by tag shas' do
        recorder = ActiveRecord::QueryRecorder.new { execute }
        lookup_query = pipeline_lookup_query(recorder)
        expected_shas = refs.filter_map { |ref| ref.dereferenced_target&.sha }.uniq
        tag_object_sha = tags.find { |tag| tag.name == 'v1.1.0' }.target

        expect(lookup_query).to match(sha_in_predicate)
        expect(lookup_query[sha_in_predicate, 1].scan(/\h{40}/)).to match_array(expected_shas)
        expect(lookup_query[sha_in_predicate, 1]).not_to include(tag_object_sha)
      end

      context 'when the sha lookup flag is disabled' do
        before do
          stub_feature_flags(branches_page_pipeline_lookup_by_sha: false)
        end

        it 'does not filter tag pipeline lookups by sha' do
          recorder = ActiveRecord::QueryRecorder.new { execute }
          lookup_query = pipeline_lookup_query(recorder)

          expect(lookup_query).to be_present
          expect(lookup_query).not_to match(sha_in_predicate)
          expect(pipeline_for_v1_0_0_status).to eq(tags_v1_0_0_pipeline_2)
        end
      end
    end

    context 'when ref_type is :heads' do
      let(:ref_type) { :heads }

      let_it_be(:outdated_master_pipeline) do
        create(:ci_pipeline, :success, project: project, ref: 'master', sha: project.commit('master~1').sha)
      end

      it 'returns the latest statuses from the newest matching branch pipelines' do
        expect(pipeline_for_wip_status).to eq(heads_wip_pipeline)
        expect(pipeline_for_master_status).to eq(heads_master_pipeline_2)
        expect(pipeline_for_v1_1_0_status).to eq(heads_v1_1_0_pipeline)
        expect(pipeline_for_v1_0_0_status).to be_nil
      end

      it 'filters the branch pipeline lookup by all head shas' do
        recorder = ActiveRecord::QueryRecorder.new { execute }
        lookup_query = pipeline_lookup_query(recorder)
        expected_shas = refs.filter_map { |ref| ref.dereferenced_target&.sha }.uniq

        expect(lookup_query).to match(sha_in_predicate)
        expect(lookup_query[sha_in_predicate, 1].scan(/\h{40}/)).to match_array(expected_shas)
      end

      context 'when two branches share a head sha' do
        let(:same_head) do
          master = branches.find { |branch| branch.name == 'master' }
          Gitlab::Git::Branch.new(project.repository, 'same-head', master.target, master.dereferenced_target)
        end

        let(:refs) { super() + [same_head] }

        it 'returns the matching pipeline for each branch' do
          same_head_pipeline = create(:ci_pipeline, :success, project: project, ref: 'same-head',
            sha: project.commit('master').sha)

          expect(execute['master'].subject).to eq(heads_master_pipeline_2)
          expect(execute['same-head'].subject).to eq(same_head_pipeline)
        end
      end

      context 'when the sha lookup flag is disabled' do
        before do
          stub_feature_flags(branches_page_pipeline_lookup_by_sha: false)
        end

        it 'does not filter branch pipeline lookups by sha' do
          recorder = ActiveRecord::QueryRecorder.new { execute }
          lookup_query = pipeline_lookup_query(recorder)

          expect(lookup_query).to be_present
          expect(lookup_query).not_to match(sha_in_predicate)
          expect(pipeline_for_master_status).to eq(heads_master_pipeline_2)
        end
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
        let_it_be_with_reload(:project) { create(:project, :repository, builds_access_level: ProjectFeature::PRIVATE) }

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
        let_it_be_with_reload(:project) { create(:project, :private, :repository) }

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
