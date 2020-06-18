# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BoardsResponses do
  let(:controller_class) do
    Class.new do
      include BoardsResponses
    end
  end

  subject(:controller) { controller_class.new }

  describe '#serialize_as_json' do
    let!(:board) { create(:board) }

    it 'serializes properly' do
      expected = { "id" => board.id }

      expect(subject.serialize_as_json(board)).to include(expected)
    end
  end
end
