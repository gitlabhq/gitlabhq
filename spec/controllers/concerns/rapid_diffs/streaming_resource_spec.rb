# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RapidDiffs::StreamingResource, type: :controller, feature_category: :source_code_management do
  subject(:controller) do
    Class.new(ApplicationController) do
      include RapidDiffs::StreamingResource

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

  describe '#diffs' do
    let(:controller_instance) { controller.new }
    let(:mock_resource) { instance_double(::Commit) }
    let(:mock_diffs) { instance_double(Gitlab::Diff::FileCollection::Commit, diff_files: diff_files) }
    let(:diff_files) { [{}] }
    let(:stream) { instance_double(ActionDispatch::Response::Buffer, write: nil, close: nil) }
    let(:response) { instance_double(ActionDispatch::Response, stream: stream) }

    let(:empty_state_html) { '<empty-state>No changes</empty-state>' }
    let(:diffs_html) { '<diffs></diffs>' }

    before do
      allow(controller_instance).to receive_messages(
        resource: mock_resource,
        response: response,
        rapid_diffs_enabled?: true,
        view_context: nil,
        stream_headers: nil,
        params: ActionController::Parameters.new)
      allow(controller_instance).to receive_message_chain(:helpers, :diff_view).and_return('inline')
      allow(mock_resource).to receive(:diffs_for_streaming).and_return(mock_diffs)
      allow(mock_resource).to receive(:first_diffs_slice).with(1, any_args).and_return(diff_files)
      allow(RapidDiffs::DiffFileComponent).to receive_message_chain(:with_collection, :render_in)
        .and_return(diffs_html)
    end

    it 'renders diffs' do
      controller_instance.send(:diffs)
      expect(response.stream).to have_received(:write).with(diffs_html)
      # ensure we're not doing double work when checking for empty state
      expect(mock_resource).to have_received(:diffs_for_streaming).once
    end

    context 'when no diffs and no offset' do
      let(:diff_files) { [] }

      before do
        allow(controller_instance).to receive(:params).and_return(ActionController::Parameters.new)
        allow(controller_instance).to receive(:render), &:call
        allow(RapidDiffs::EmptyStateComponent).to receive_message_chain(:new, :call).and_return(empty_state_html)
      end

      it 'renders empty state' do
        controller_instance.send(:diffs)
        expect(response.stream).to have_received(:write).with(empty_state_html)
      end
    end

    context 'when offset is provided' do
      before do
        allow(controller_instance).to receive(:params).and_return(ActionController::Parameters.new(offset: '5'))
      end

      it 'renders diffs' do
        controller_instance.send(:diffs)
        expect(response.stream).to have_received(:write).with(diffs_html)
      end
    end
  end
end
