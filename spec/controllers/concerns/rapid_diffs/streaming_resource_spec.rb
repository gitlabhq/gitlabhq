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

  describe '#environment' do
    let(:controller_instance) { controller.new }

    context 'when environment is set' do
      let(:environment) { build(:environment) }

      before do
        controller_instance.instance_variable_set(:@environment, environment)
      end

      it 'returns the environment' do
        expect(controller_instance.send(:environment)).to eq(environment)
      end
    end

    context 'when environment is not set' do
      it 'returns nil' do
        expect(controller_instance.send(:environment)).to be_nil
      end
    end
  end

  describe '#diff_file_component' do
    let(:controller_instance) { controller.new }
    let(:diff_file) { build(:diff_file) }

    before do
      allow(controller_instance).to receive_message_chain(:helpers, :diff_view).and_return(:inline)
    end

    context 'when environment is nil' do
      it 'creates a DiffFileComponent with nil environment' do
        expect(::RapidDiffs::DiffFileComponent).to receive(:new)
                                                     .with(
                                                       diff_file: diff_file,
                                                       parallel_view: false,
                                                       environment: nil
                                                     )

        controller_instance.send(:diff_file_component, diff_file)
      end
    end

    context 'when environment is set' do
      let(:environment) { build(:environment) }

      before do
        controller_instance.instance_variable_set(:@environment, environment)
      end

      it 'creates a DiffFileComponent with the environment' do
        expect(::RapidDiffs::DiffFileComponent).to receive(:new)
                                                     .with(
                                                       diff_file: diff_file,
                                                       parallel_view: false,
                                                       environment: environment
                                                     )

        controller_instance.send(:diff_file_component, diff_file)
      end
    end

    context 'when view is parallel' do
      let(:environment) { build(:environment) }

      before do
        allow(controller_instance).to receive_message_chain(:helpers, :diff_view).and_return(:parallel)
        controller_instance.instance_variable_set(:@environment, environment)
      end

      it 'creates a DiffFileComponent with parallel_view: true' do
        expect(::RapidDiffs::DiffFileComponent).to receive(:new)
                                                     .with(
                                                       diff_file: diff_file,
                                                       parallel_view: true,
                                                       environment: environment
                                                     )

        controller_instance.send(:diff_file_component, diff_file)
      end
    end
  end

  describe '#diff_files_collection' do
    let(:controller_instance) { controller.new }
    let(:diff_files) { [build(:diff_file), build(:diff_file)] }

    before do
      allow(controller_instance).to receive_message_chain(:helpers, :diff_view).and_return(:inline)
    end

    context 'when environment is nil' do
      it 'creates a DiffFileComponent collection with nil environment' do
        expect(::RapidDiffs::DiffFileComponent).to receive(:with_collection)
                                                     .with(
                                                       diff_files,
                                                       parallel_view: false,
                                                       environment: nil
                                                     )

        controller_instance.send(:diff_files_collection, diff_files)
      end
    end

    context 'when environment is set' do
      let(:environment) { build(:environment) }

      before do
        controller_instance.instance_variable_set(:@environment, environment)
      end

      it 'creates a DiffFileComponent collection with the environment' do
        expect(::RapidDiffs::DiffFileComponent).to receive(:with_collection)
                                                     .with(
                                                       diff_files,
                                                       parallel_view: false,
                                                       environment: environment
                                                     )

        controller_instance.send(:diff_files_collection, diff_files)
      end
    end

    context 'when view is parallel' do
      let(:environment) { build(:environment) }

      before do
        allow(controller_instance).to receive_message_chain(:helpers, :diff_view).and_return(:parallel)
        controller_instance.instance_variable_set(:@environment, environment)
      end

      it 'creates a DiffFileComponent collection with parallel_view: true' do
        expect(::RapidDiffs::DiffFileComponent).to receive(:with_collection)
                                                     .with(
                                                       diff_files,
                                                       parallel_view: true,
                                                       environment: environment
                                                     )

        controller_instance.send(:diff_files_collection, diff_files)
      end
    end
  end

  describe '#diffs' do
    let(:controller_instance) { controller.new }
    let(:mock_resource) { instance_double(::Commit) }
    let(:mock_diffs) { instance_double(Gitlab::Diff::FileCollection::Commit, diff_files: diff_files) }
    let(:diff_files) { [build(:diff_file)] }
    let(:stream) { instance_double(ActionDispatch::Response::Buffer, write: nil, close: nil, closed?: false) }
    let(:response) { instance_double(ActionDispatch::Response, stream: stream) }

    let(:empty_state_html) { '<empty-state>No changes</empty-state>' }
    let(:diff_html) { '<diff-file></diff-file>' }

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
                                                .and_return(diff_html)
      allow(RapidDiffs::DiffFileComponent).to receive_message_chain(:new, :call)
                                                .and_return(diff_html)
      allow(RapidDiffs::DiffFileComponent).to receive_message_chain(:new, :render_in)
                                                .and_return(diff_html)
    end

    it 'renders diffs' do
      controller_instance.send(:diffs)
      expect(response.stream).to have_received(:write).with(diff_html)
      # ensure we're not doing double work when checking for empty state
      expect(mock_resource).to have_received(:diffs_for_streaming).once
    end

    context 'with non-sequential collapsed diffs' do
      let(:diff_files) do
        collapsed_diff = build(:diff_file)
        expanded_diff = build(:diff_file)
        allow(collapsed_diff).to receive(:no_preview?).and_return(true)
        allow(expanded_diff).to receive(:no_preview?).and_return(false)
        [expanded_diff, collapsed_diff, expanded_diff, collapsed_diff]
      end

      it 'renders diffs' do
        controller_instance.send(:diffs)
        expect(response.stream).to have_received(:write).with(diff_html).exactly(diff_files.count).times
        # ensure we're not doing double work when checking for empty state
        expect(mock_resource).to have_received(:diffs_for_streaming).once
      end
    end

    context 'when no diffs and no offset' do
      let(:diff_files) { [] }

      before do
        allow(controller_instance).to receive(:params).and_return(ActionController::Parameters.new)
        allow(controller_instance).to receive(:render).with(anything, layout: false), &:call
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
        expect(response.stream).to have_received(:write).with(diff_html)
      end
    end

    context 'when stream is already closed' do
      before do
        allow(controller_instance).to receive(:stream_diff_files).and_wrap_original do |original_method, *args|
          original_method.call(*args)
          allow(stream).to receive(:closed?).and_return(true)
        end
      end

      it 'does not raise an IOError when closing the stream' do
        expect { controller_instance.send(:diffs) }.not_to raise_error
        expect(stream).not_to have_received(:close)
      end
    end

    context 'when stream is lost' do
      where(:error) do
        [
          [[ActionController::Live::ClientDisconnected]],
          [[IOError, 'closed stream']]
        ]
      end

      with_them do
        before do
          allow(stream).to receive(:write).and_raise(*error)
        end

        it 'silently handles the disconnection' do
          expect { controller_instance.send(:diffs) }.not_to raise_error
          expect(Gitlab::AppLogger).not_to receive(:error)
        end
      end
    end
  end
end
