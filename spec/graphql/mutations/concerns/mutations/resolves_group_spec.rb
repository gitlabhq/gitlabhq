# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::ResolvesGroup do
  let(:mutation_class) do
    Class.new(Mutations::BaseMutation) do
      include Mutations::ResolvesGroup
    end
  end

  let(:context) { {} }

  subject(:mutation) { mutation_class.new(object: nil, context: context, field: nil) }

  it 'uses the GroupsResolver to resolve groups by path' do
    group = create(:group)

    expect(Resolvers::GroupResolver).to receive(:new).with(object: nil, context: context, field: nil).and_call_original
    expect(mutation.resolve_group(full_path: group.full_path).sync).to eq(group)
  end
end
