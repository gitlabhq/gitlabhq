# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::PackagesBaseResolver do
  include GraphqlHelpers

  describe '#resolve' do
    subject { resolve(described_class) }

    it 'throws an error' do
      expect { subject }.to raise_error(NotImplementedError)
    end
  end
end
