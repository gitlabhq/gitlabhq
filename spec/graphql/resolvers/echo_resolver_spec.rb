# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::EchoResolver do
  include GraphqlHelpers

  let(:current_user) { create(:user) }
  let(:text) { 'Message test' }

  specify do
    expect(described_class).to have_non_null_graphql_type(::GraphQL::Types::String)
  end

  describe '#resolve' do
    it 'echoes text and username' do
      expect(resolve_echo(text)).to eq %("#{current_user.username}" says: #{text})
    end

    it 'echoes text and nil as username' do
      expect(resolve_echo(text, { current_user: nil })).to eq "nil says: #{text}"
    end
  end

  def resolve_echo(text, context = { current_user: current_user })
    resolve(described_class, obj: nil, args: { text: text }, ctx: context)
  end
end
