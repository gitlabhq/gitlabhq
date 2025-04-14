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

  describe '#stream_diff_files' do
    let(:controller_instance) { controller.new }
    let(:mock_resource) { instance_double(::Commit) }
    let(:mock_diffs) { instance_double(Gitlab::Diff::FileCollection::Commit, diff_files: diff_files) }
    let(:diff_files) { [] }
    let(:response) do
      instance_double(ActionDispatch::Response,
        stream: instance_double(ActionDispatch::Response::Buffer, write: nil))
    end

    let(:empty_state_html) { '<empty-state>No changes</empty-state>' }

    before do
      allow(controller_instance).to receive_messages(resource: mock_resource, response: response)
      allow(controller_instance).to receive(:view_context)
      allow(mock_resource).to receive(:diffs_for_streaming).and_return(mock_diffs)
    end

    context 'when no diffs and no offset' do
      before do
        allow(controller_instance).to receive(:params).and_return(ActionController::Parameters.new)
        allow(RapidDiffs::EmptyStateComponent).to receive_message_chain(:new, :render_in).and_return(empty_state_html)
      end

      it 'renders empty state' do
        controller_instance.send(:stream_diff_files, {})

        expect(response.stream).to have_received(:write).with(empty_state_html)
      end
    end

    context 'when offset is provided' do
      before do
        allow(controller_instance).to receive(:params).and_return(ActionController::Parameters.new(offset: '5'))
      end

      it 'does not render empty state' do
        expect(RapidDiffs::EmptyStateComponent).not_to receive(:new)

        controller_instance.send(:stream_diff_files, {})
      end
    end
  end
end
