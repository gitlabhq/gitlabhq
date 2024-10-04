# frozen_string_literal: true

require 'spec_helper'

RSpec.describe StreamDiffs, type: :controller, feature_category: :source_code_management do
  subject(:controller) do
    Class.new(ApplicationController) do
      include StreamDiffs

      def call_resource
        resource
      end

      def call_options
        options
      end
    end
  end

  describe '#resource' do
    it 'raises NotImplementedError' do
      expect { controller.new.call_resource }.to raise_error(NotImplementedError)
    end
  end

  describe '#options' do
    it 'returns empty hash' do
      expect(controller.new.call_options).to eq({})
    end
  end
end
