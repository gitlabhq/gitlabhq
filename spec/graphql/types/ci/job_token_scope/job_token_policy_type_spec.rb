# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Types::Ci::JobTokenScope::JobTokenPolicyType, feature_category: :secrets_management do
  specify { expect(described_class.graphql_name).to eq('JobTokenPolicy') }
  specify { expect(described_class).to have_graphql_fields(%i[text value type description]) }
end
