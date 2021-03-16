# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::BaseArgument do
  include_examples 'Gitlab-style deprecations' do
    let_it_be(:field) do
      Types::BaseField.new(name: 'field', type: String, null: true)
    end

    let(:base_args) { { name: 'test', type: String, required: false, owner: field } }

    def subject(args = {})
      described_class.new(**base_args.merge(args))
    end
  end
end
