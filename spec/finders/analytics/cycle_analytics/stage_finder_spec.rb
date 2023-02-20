# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Analytics::CycleAnalytics::StageFinder do
  let(:project) { build(:project) }

  let(:stage_id) { { id: Gitlab::Analytics::CycleAnalytics::DefaultStages.names.first } }

  subject { described_class.new(parent: project.project_namespace, stage_id: stage_id[:id]).execute }

  context 'when looking up in-memory default stage by name exists' do
    it { expect(subject).not_to be_persisted }
    it { expect(subject.name).to eq(stage_id[:id]) }
  end

  context 'when in-memory default stage cannot be found' do
    before do
      stage_id[:id] = 'unknown_default_stage'
    end

    it { expect { subject }.to raise_error(ActiveRecord::RecordNotFound) }
  end
end
