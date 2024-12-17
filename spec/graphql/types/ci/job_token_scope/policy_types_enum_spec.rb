# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Types::Ci::JobTokenScope::PolicyTypesEnum, feature_category: :secrets_management do
  it 'the correct enum members' do
    expect(described_class.values).to match(
      'READ' => have_attributes(value: :read, description: 'Read-only access to the resource.'),
      'ADMIN' => have_attributes(value: :admin, description: 'Admin access to the resource.')
    )
  end
end
