# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Claim for DeployKey', feature_category: :cell do
  let_it_be(:user) { create(:user) }

  subject! { build(:deploy_key, user: user) }

  it_behaves_like 'creating new claims'
  it_behaves_like 'deleting existing claims'
end
