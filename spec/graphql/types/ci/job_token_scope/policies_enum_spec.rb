# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Types::Ci::JobTokenScope::PoliciesEnum, feature_category: :secrets_management do
  it 'exposes all policies' do
    expect(described_class.values.keys).to match_array(%w[
      READ_CONTAINERS
      ADMIN_CONTAINERS
      READ_DEPLOYMENTS
      ADMIN_DEPLOYMENTS
      READ_ENVIRONMENTS
      ADMIN_ENVIRONMENTS
      READ_JOBS
      ADMIN_JOBS
      READ_PACKAGES
      ADMIN_PACKAGES
      READ_RELEASES
      ADMIN_RELEASES
      READ_SECURE_FILES
      ADMIN_SECURE_FILES
      READ_TERRAFORM_STATE
      ADMIN_TERRAFORM_STATE
    ])
  end
end
