# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Pajamas::Component do
  describe '#filter_attribute' do
    let(:allowed) { %w[default something] }

    it 'returns default value when no value is given' do
      value = subject.send(:filter_attribute, nil, allowed, default: 'default')

      expect(value).to eq('default')
    end

    it 'returns default value when invalid value is given' do
      value = subject.send(:filter_attribute, 'invalid', allowed, default: 'default')

      expect(value).to eq('default')
    end

    it 'returns given value when it is part of allowed list' do
      value = subject.send(:filter_attribute, 'something', allowed, default: 'default')

      expect(value).to eq('something')
    end
  end
end
