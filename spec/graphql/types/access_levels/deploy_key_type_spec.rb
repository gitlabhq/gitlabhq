# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['AccessLevelDeployKey'], feature_category: :source_code_management do
  subject { described_class }

  let(:fields) { %i[id title expires_at user] }

  it { is_expected.to require_graphql_authorizations(:read_deploy_key) }

  it { is_expected.to have_graphql_fields(fields).at_least }
end
