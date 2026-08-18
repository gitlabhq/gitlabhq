# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Claim for PagesDomain', feature_category: :cell do
  let_it_be(:project) { create(:project) }

  subject! { build(:pages_domain, project: project) }

  it_behaves_like 'creating new claims'
  it_behaves_like 'deleting existing claims'
  it_behaves_like 'updating existing claims' do
    let(:transform_attributes) { { domain: "updated-#{subject.domain}" } }
  end

  context 'when claims feature is disabled' do
    before do
      stub_feature_flags(cells_claims_pages_domains: false)
    end

    it_behaves_like 'not creating claims'
    it_behaves_like 'not deleting claims'
  end
end
