# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Claim for Organizations::Organization', feature_category: :cell do
  subject! { build(:organization) }

  it_behaves_like 'creating new claims'
  it_behaves_like 'deleting existing claims'
  it_behaves_like 'updating existing claims' do
    let(:transform_attributes) { { path: subject.path.reverse } }
  end
end
