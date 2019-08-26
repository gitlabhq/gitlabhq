# frozen_string_literal: true

require 'spec_helper'

describe Resolvers::EchoResolver do
  include GraphqlHelpers

  let(:current_user) { create(:user) }
  let(:text) { 'Message test' }

  describe '#resolve' do
    it 'echoes text and username' do
      expect(resolve_echo(text)).to eq %Q("#{current_user.username}" says: #{text})
    end

    it 'echoes text and nil as username' do
      expect(resolve_echo(text, { current_user: nil })).to eq "nil says: #{text}"
    end
  end

  def resolve_echo(text, context = { current_user: current_user })
    resolve(described_class, obj: nil, args: { text: text }, ctx: context)
  end
end
