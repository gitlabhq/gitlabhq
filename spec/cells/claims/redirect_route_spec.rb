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
end
