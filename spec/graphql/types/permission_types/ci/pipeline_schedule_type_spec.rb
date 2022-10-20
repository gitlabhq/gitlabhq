# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::Ci::PipelineScheduleType do
  specify { expect(described_class).to expose_permissions_using(Types::PermissionTypes::Ci::PipelineSchedules) }
end
