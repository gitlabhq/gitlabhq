# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Claim for Group', feature_category: :cell do
  subject! { build(:group) }

  shared_context 'with claims records for Group' do
    def claims_records(only: {})
      claims_records_for(subject, only: only) +
        claims_records_for(subject.route, only: only)
    end
  end

  it_behaves_like 'creating new claims' do
    include_context 'with claims records for Group'
  end

  it_behaves_like 'deleting existing claims' do
    include_context 'with claims records for Group'
  end

  context 'when claims feature is disabled' do
    before do
      stub_feature_flags(cells_claims_routes: false)
      stub_feature_flags(cells_claims_namespaces: false)
    end

    it_behaves_like 'not creating claims'
    it_behaves_like 'not deleting claims'
  end
end
