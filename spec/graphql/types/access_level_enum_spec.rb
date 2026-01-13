# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['AccessLevelEnum'] do
  specify { expect(described_class.graphql_name).to eq('AccessLevelEnum') }

  it 'exposes all the existing access levels' do
    expect(described_class.values.keys)
      .to include(*%w[NO_ACCESS MINIMAL_ACCESS GUEST PLANNER REPORTER SECURITY_MANAGER DEVELOPER MAINTAINER OWNER])
  end

  context 'when security manager role is disabled', :disable_security_manager do
    it 'exposes all user roles without security manager' do
      expect(described_class.values.keys).not_to include('SECURITY_MANAGER')
    end
  end
end
