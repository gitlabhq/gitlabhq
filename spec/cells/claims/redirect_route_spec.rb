# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Claim for RedirectRoute', feature_category: :cell do
  let_it_be(:group) { create(:group) }

  subject! { build(:redirect_route, source: group) }

  it_behaves_like 'creating new claims'
  it_behaves_like 'deleting existing claims'
  it_behaves_like 'updating existing claims' do
    let(:transform_attributes) { { path: subject.path.reverse } }
  end

  context 'when claims feature is disabled' do
    before do
      stub_feature_flags(cells_claims_routes: false)
    end

    it_behaves_like 'not creating claims'
    it_behaves_like 'not deleting claims'
  end
end
