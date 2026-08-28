# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Claim for GpgKey', feature_category: :cell do
  let_it_be(:user) { create(:user) }

  subject! { build(:gpg_key, user: user) }

  it_behaves_like 'creating new claims'
  it_behaves_like 'deleting existing claims'
end
