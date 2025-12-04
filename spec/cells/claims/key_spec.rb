# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Claim for Key', feature_category: :cell do
  subject! { build(:key) }

  it_behaves_like 'creating new claims'
  it_behaves_like 'deleting existing claims'
end
