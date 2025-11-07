# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Claim for Organizations::Organization', feature_category: :cell do
  it_behaves_like 'creating new claims', factory_name: :organization do
    let(:transform_attributes) { { path: subject.path.reverse } }
  end
end
