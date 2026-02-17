# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Claim for Key', feature_category: :cell do
  subject! { build(:key) }

  it_behaves_like 'creating new claims'
  it_behaves_like 'deleting existing claims'

  context 'when claims feature is disabled' do
    before do
      stub_feature_flags(cells_claims_keys: false)
    end

    it_behaves_like 'not creating claims'
    it_behaves_like 'not deleting claims'
  end
end
