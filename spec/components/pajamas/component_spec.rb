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

  describe '#format_options' do
    it 'merges CSS classes and additional options' do
      expect(
        subject.send(
          :format_options,
          options: { foo: 'bar', class: 'gl-flex gl-py-5' },
          css_classes: %w[gl-px-5 gl-mt-5],
          additional_options: { baz: 'bax' }
        )
      ).to match({
        foo: 'bar',
        baz: 'bax',
        class: ['gl-px-5', 'gl-mt-5', 'gl-flex gl-py-5']
      })
    end
  end
end
