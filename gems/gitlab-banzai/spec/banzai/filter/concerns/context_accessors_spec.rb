# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Banzai::Filter::Concerns::ContextAccessors do
  let(:accessor_class) do
    Class.new do
      include Banzai::Filter::Concerns::ContextAccessors

      attr_reader :context

      def initialize(context)
        @context = context
      end
    end
  end

  it 'reads each supported key from the context' do
    context = { project: :a_project, current_user: :a_user, group: :a_group, author: :an_author, user: :a_user_key }

    accessors = accessor_class.new(context)

    expect(accessors.project).to eq(:a_project)
    expect(accessors.current_user).to eq(:a_user)
    expect(accessors.group).to eq(:a_group)
    expect(accessors.author).to eq(:an_author)
    expect(accessors.user).to eq(:a_user_key)
  end

  it 'returns nil for keys the context does not carry' do
    expect(accessor_class.new({}).project).to be_nil
  end
end
