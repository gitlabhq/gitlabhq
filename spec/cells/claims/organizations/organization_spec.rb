# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Claim for Organizations::Organization', feature_category: :cell do
  subject! { build(:organization) }

  it_behaves_like 'creating new claims'
  it_behaves_like 'deleting existing claims'
  it_behaves_like 'updating existing claims' do
    let(:transform_attributes) { { path: subject.path.reverse } }
  end

  context 'when claims feature is disabled' do
    before do
      stub_feature_flags(cells_claims_organizations: false)
    end

    it_behaves_like 'not creating claims'
    it_behaves_like 'not deleting claims'
  end
end
