# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::Ci::PipelineType do
  specify { expect(described_class.graphql_name).to eq('Pipeline') }

  specify { expect(described_class).to expose_permissions_using(Types::PermissionTypes::Ci::Pipeline) }
end
