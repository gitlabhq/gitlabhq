require 'spec_helper'

describe BillingPlansHelper do
  describe '#current_plan?' do
    it 'returns true when current_plan' do
      plan = Hashie::Mash.new(purchase_link: { action: 'current_plan' })

      expect(helper.current_plan?(plan)).to be_truthy
    end

    it 'return false when not current_plan' do
      plan = Hashie::Mash.new(purchase_link: { action: 'upgrade' })

      expect(helper.current_plan?(plan)).to be_falsy
    end
  end
end
