# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Types::Ci::JobTokenScope::PolicyCategoriesEnum, feature_category: :secrets_management do
  it 'exposes all categories' do
    expect(described_class.values.keys).to match_array(%w[
      CONTAINERS
      DEPLOYMENTS
      ENVIRONMENTS
      JOBS
      PACKAGES
      RELEASES
      SECURE_FILES
      TERRAFORM_STATE
    ])
  end
end
