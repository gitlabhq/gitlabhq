# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Admin::PlansFinder do
  let_it_be(:premium_plan) { create(:plan, name: 'premium') }
  let_it_be(:ultimate_plan) { create(:plan, name: 'ultimate') }

  describe '#execute' do
    context 'with no params' do
      it 'returns all plans' do
        found = described_class.new.execute

        expect(found).to match_array([premium_plan, ultimate_plan])
      end
    end

    context 'with missing name in params' do
      before do
        @params = { title: 'ultimate_plan' }
      end

      it 'returns all plans' do
        found = described_class.new(@params).execute

        expect(found).to match_array([premium_plan, ultimate_plan])
      end
    end

    context 'with existing name in params' do
      before do
        @params = { name: 'ultimate' }
      end

      it 'returns the plan' do
        found = described_class.new(@params).execute

        expect(found).to match(ultimate_plan)
      end
    end

    context 'with non-existing name in params' do
      before do
        @params = { name: 'non-existing-plan' }
      end

      it 'returns nil' do
        found = described_class.new(@params).execute

        expect(found).to be_nil
      end
    end
  end
end
