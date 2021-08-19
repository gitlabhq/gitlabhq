# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::BaseArgument do
  let_it_be(:field) do
    Types::BaseField.new(name: 'field', type: String, null: true)
  end

  let(:base_args) { { name: 'test', type: String, required: false, owner: field } }

  def subject(args = {})
    described_class.new(**base_args.merge(args))
  end

  include_examples 'Gitlab-style deprecations'

  describe 'required argument declarations' do
    it 'accepts nullable, required arguments' do
      arguments = base_args.merge({ required: :nullable })

      expect { subject(arguments) }.not_to raise_error
    end

    it 'accepts required, non-nullable arguments' do
      arguments = base_args.merge({ required: true })

      expect { subject(arguments) }.not_to raise_error
    end

    it 'accepts non-required arguments' do
      arguments = base_args.merge({ required: false })

      expect { subject(arguments) }.not_to raise_error
    end

    it 'accepts no required argument declaration' do
      arguments = base_args

      expect { subject(arguments) }.not_to raise_error
    end
  end
end
