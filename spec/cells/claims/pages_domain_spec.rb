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
end
