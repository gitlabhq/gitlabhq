# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::Security::CiConfiguration::ConfigureSastIac do
  include GraphqlHelpers

  let(:service) { ::Security::CiConfiguration::SastIacCreateService }

  subject { resolve(described_class, args: { project_path: project.full_path }, ctx: query_context) }

  include_examples 'graphql mutations security ci configuration'
end
