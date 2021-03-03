# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Admin::PlansFinder do
  let_it_be(:plan1) { create(:plan, name: 'plan1') }
  let_it_be(:plan2) { create(:plan, name: 'plan2') }

  describe '#execute' do
    context 'with no params' do
      it 'returns all plans' do
        found = described_class.new.execute

        expect(found).to match_array([plan1, plan2])
      end
    end

    context 'with missing name in params' do
      before do
        @params = { title: 'plan2' }
      end

      it 'returns all plans' do
        found = described_class.new(@params).execute

        expect(found).to match_array([plan1, plan2])
      end
    end

    context 'with existing name in params' do
      before do
        @params = { name: 'plan2' }
      end

      it 'returns the plan' do
        found = described_class.new(@params).execute

        expect(found).to match(plan2)
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
