# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::PackagesBaseResolver do
  include GraphqlHelpers

  let(:args) do
    {
      sort: :created_desc,
      package_name: nil,
      package_type: nil,
      package_version: nil,
      status: nil,
      include_versionless: false
    }
  end

  describe '#resolve' do
    subject do
      resolve(described_class, args: args, arg_style: :internal)
    end

    it 'throws an error' do
      expect { subject }.to raise_error(NotImplementedError)
    end
  end
end
