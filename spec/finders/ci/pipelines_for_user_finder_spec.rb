# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::PipelinesForUserFinder, feature_category: :continuous_integration do
  let_it_be(:user) { create(:user) }
  let_it_be(:other_user) { create(:user) }
  let_it_be(:project) { create(:project) }
  let_it_be(:other_project) { create(:project) }

  let_it_be(:older_pipeline) do
    create(:ci_empty_pipeline, project: project, user: user, status: 'success', created_at: 3.days.ago)
  end

  let_it_be(:newer_pipeline) do
    create(:ci_empty_pipeline, project: other_project, user: user, source: :web, created_at: 1.day.ago)
  end

  let_it_be(:child_pipeline) do
    create(:ci_empty_pipeline, project: project, user: user, source: :parent_pipeline)
  end

  let_it_be(:other_user_pipeline) do
    create(:ci_empty_pipeline, project: project, user: other_user)
  end

  describe '#execute' do
    let(:params) { {} }

    subject(:execute) { described_class.new(user, params).execute }

    it 'returns pipelines triggered by the user across projects, newest first, without child pipelines' do
      expect(execute).to eq([newer_pipeline, older_pipeline])
    end

    it 'excludes pipelines outside the recent partitions' do
      allow(Ci::Partition).to receive(:recent_ids).and_return([non_existing_record_id])

      expect(execute).to be_empty
    end

    it 'excludes pipelines without a created_at, which cannot be cursor-paginated' do
      pipeline = create(:ci_empty_pipeline, project: project, user: user)
      pipeline.update_column(:created_at, nil)

      expect(execute).not_to include(pipeline)
    end

    context 'with a source param' do
      let(:params) { { source: 'web' } }

      it 'returns pipelines with the given source' do
        expect(execute).to contain_exactly(newer_pipeline)
      end
    end

    context 'with source set to parent_pipeline' do
      let(:params) { { source: 'parent_pipeline' } }

      it 'returns child pipelines' do
        expect(execute).to contain_exactly(child_pipeline)
      end
    end

    context 'with a created_after param' do
      let(:params) { { created_after: 2.days.ago } }

      it 'returns pipelines created after the given time' do
        expect(execute).to contain_exactly(newer_pipeline)
      end
    end

    context 'with a created_before param' do
      let(:params) { { created_before: 2.days.ago } }

      it 'returns pipelines created before the given time' do
        expect(execute).to contain_exactly(older_pipeline)
      end
    end
  end

  describe '.visible_to' do
    let_it_be(:member_project) { create(:project, maintainers: user) }
    let_it_be(:readable_pipeline) { create(:ci_empty_pipeline, project: member_project, user: user) }

    it 'returns only pipelines from projects the user can read' do
      visible = described_class.visible_to([readable_pipeline, older_pipeline], user)

      expect(visible).to contain_exactly(readable_pipeline)
    end

    it 'preloads project policy data for the given pipelines' do
      expect_next_instance_of(Preloaders::ProjectPolicyPreloader, [member_project, project], user) do |preloader|
        expect(preloader).to receive(:execute).and_call_original
      end

      described_class.visible_to([readable_pipeline, older_pipeline], user)
    end

    it 'returns an empty array when given no pipelines' do
      expect(described_class.visible_to([], user)).to eq([])
    end
  end
end
