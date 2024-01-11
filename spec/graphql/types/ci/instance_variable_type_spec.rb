# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['CiInstanceVariable'] do
  specify { expect(described_class.interfaces).to contain_exactly(Types::Ci::VariableInterface) }

  specify do
    expect(described_class).to have_graphql_fields(:environment_scope, :masked, :protected, :description).at_least
  end
end
