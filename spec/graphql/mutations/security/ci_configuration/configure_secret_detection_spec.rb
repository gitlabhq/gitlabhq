# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::Security::CiConfiguration::ConfigureSecretDetection do
  include GraphqlHelpers

  let(:service) { ::Security::CiConfiguration::SecretDetectionCreateService }

  subject { resolve(described_class, args: { project_path: project.full_path }, ctx: { current_user: user }) }

  include_examples 'graphql mutations security ci configuration'
end
