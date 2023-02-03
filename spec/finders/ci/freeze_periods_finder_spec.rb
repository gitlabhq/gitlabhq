# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::FreezePeriodsFinder, feature_category: :release_orchestration do
  subject(:finder) { described_class.new(project, user).execute }

  let(:project) { create(:project, :private) }
  let(:user) { create(:user) }
  let!(:freeze_period_1) { create(:ci_freeze_period, project: project, created_at: 2.days.ago) }
  let!(:freeze_period_2) { create(:ci_freeze_period, project: project, created_at: 1.day.ago) }

  shared_examples_for 'returns nothing' do
    specify do
      is_expected.to be_empty
    end
  end

  shared_examples_for 'returns freeze_periods ordered by created_at asc' do
    it 'returns freeze_periods ordered by created_at' do
      expect(subject.count).to eq(2)
      expect(subject.pluck('id')).to eq([freeze_period_1.id, freeze_period_2.id])
    end
  end

  context 'when user is a maintainer' do
    before do
      project.add_maintainer(user)
    end

    it_behaves_like 'returns freeze_periods ordered by created_at asc'
  end

  context 'when user is a guest' do
    before do
      project.add_guest(user)
    end

    it_behaves_like 'returns nothing'
  end

  context 'when user is a developer' do
    before do
      project.add_developer(user)
    end

    it_behaves_like 'returns freeze_periods ordered by created_at asc'
  end

  context 'when user is not a project member' do
    it_behaves_like 'returns nothing'

    context 'when project is public' do
      let(:project) { create(:project, :public) }

      it_behaves_like 'returns nothing'
    end
  end
end
