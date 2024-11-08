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
        streaming_diff_options
      end

      def diff_options
        {
          ignore_whitespace_change: false,
          expanded: false,
          use_extra_viewer_as_main: true,
          offset_index: 0
        }
      end
    end
  end

  describe '#resource' do
    it 'raises NotImplementedError' do
      expect { controller.new.call_resource }.to raise_error(NotImplementedError)
    end
  end

  describe '#options' do
    it 'returns hash of diff_options' do
      expect(controller.new.call_options).to eq({
        ignore_whitespace_change: false,
        expanded: false,
        use_extra_viewer_as_main: true,
        offset_index: 0
      })
    end
  end

  describe '#request' do
    it 'forces format as HTML' do
      expect(controller.new.request.format.to_s).to eq('text/html')
    end
  end
end
