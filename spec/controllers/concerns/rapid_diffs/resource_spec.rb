# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RapidDiffs::Resource, type: :controller, feature_category: :source_code_management do
  subject(:controller) do
    Class.new(ApplicationController) do
      include RapidDiffs::Resource

      def call_complete_diff_path
        complete_diff_path
      end

      def call_email_format_path
        email_format_path
      end

      def call_diff_file_component(args)
        diff_file_component(args)
      end

      def call_find_diff_file(extra_options, old_path, new_path)
        find_diff_file(extra_options, old_path, new_path)
      end

      def with_custom_diff_options
        yield({})
      end

      attr_accessor :rapid_diffs_presenter
    end
  end

  let_it_be(:offset) { 5 }
  let_it_be(:diff_view) { :inline }
  let_it_be(:sha) { "913c66a37b4a45b9769037c55c2d238bd0942d2e" }
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:commit) { project.commit_by(oid: sha) }

  describe '#complete_diff_path' do
    it 'returns nil' do
      expect(controller.new.call_complete_diff_path).to be_nil
    end
  end

  describe '#email_format_path' do
    it 'returns nil' do
      expect(controller.new.call_email_format_path).to be_nil
    end
  end

  describe '#diff_file_component' do
    it 'initializes a DiffFileComponent with the given arguments' do
      args = { diff_file: instance_double(Gitlab::Git::Diff), parallel_view: :parallel }

      expect(RapidDiffs::DiffFileComponent).to receive(:new).with(**args, environment: nil)

      controller.new.call_diff_file_component(args)
    end

    context 'when environment is nil' do
      it 'creates a DiffFileComponent with nil environment' do
        base_args = { diff_file: instance_double(Gitlab::Git::Diff) }

        expect(::RapidDiffs::DiffFileComponent).to receive(:new)
                                                     .with(**base_args, environment: nil)

        controller.new.call_diff_file_component(base_args)
      end
    end

    context 'when plain_view is provided' do
      it 'passes plain_view to DiffFileComponent' do
        args = { diff_file: instance_double(Gitlab::Git::Diff), parallel_view: false, plain_view: true }

        expect(RapidDiffs::DiffFileComponent).to receive(:new).with(**args, environment: nil)

        controller.new.call_diff_file_component(args)
      end
    end
  end

  describe '#find_diff_file' do
    let(:controller_instance) { controller.new }
    let(:diff_file) { instance_double(Gitlab::Git::Diff) }
    let(:diff_files) { [diff_file] }
    let(:presenter) { instance_double(RapidDiffs::BasePresenter) }
    let(:extra_options) { { expanded: true } }
    let(:old_path) { 'old_path.rb' }
    let(:new_path) { 'new_path.rb' }

    before do
      controller_instance.rapid_diffs_presenter = presenter
      allow(presenter).to receive(:diff_files).with(
        hash_including(paths: [old_path, new_path], expanded: true)
      ).and_return(diff_files)
    end

    it 'calls diff_files on presenter with merged options and returns the first diff file' do
      expect(controller_instance.call_find_diff_file(extra_options, old_path, new_path)).to eq(diff_file)
    end
  end

  describe '#environment' do
    it 'returns nil by default' do
      controller_instance = controller.new

      expect(controller_instance.send(:environment)).to be_nil
    end

    context 'when environment instance variable is set' do
      it 'returns the environment' do
        controller_instance = controller.new
        environment = instance_double(Environment)
        controller_instance.instance_variable_set(:@environment, environment)

        expect(controller_instance.send(:environment)).to eq(environment)
      end
    end
  end

  describe '#diff_file' do
    let(:controller_instance) { controller.new }
    let(:blob_double) { instance_double(Blob, raw_size: 1000) }
    let(:diff_file_double) do
      instance_double(Gitlab::Diff::File, whitespace_only?: false, blob: blob_double)
    end

    let(:diff_files_collection) { [diff_file_double] }
    let(:presenter_double) { instance_double(RapidDiffs::BasePresenter) }
    let(:component_double) { instance_double(RapidDiffs::DiffFileComponent) }
    let(:params_hash) { { old_path: 'file.rb', new_path: 'file.rb' } }

    before do
      controller_instance.rapid_diffs_presenter = presenter_double
      allow(controller_instance).to receive_messages(
        diff_file_params: ActionController::Parameters.new(params_hash),
        diff_view: :inline
      )
      allow(controller_instance).to receive(:render)
      allow(controller_instance).to receive(:render_404)
      allow(controller_instance).to receive(:head)
      allow(Gitlab::CurrentSettings).to receive(:diff_max_patch_bytes).and_return(10_000)
      allow(RapidDiffs::DiffFileComponent).to receive(:new).and_return(component_double)
      allow(presenter_double).to receive(:diff_files).and_return(diff_files_collection)
    end

    context 'when rapid_diffs_presenter is not present' do
      before do
        controller_instance.rapid_diffs_presenter = nil
      end

      it 'renders 404' do
        controller_instance.diff_file

        expect(controller_instance).to have_received(:render_404)
      end
    end

    context 'when diff_file is not found' do
      let(:diff_files_collection) { [] }

      it 'renders 404' do
        controller_instance.diff_file

        expect(controller_instance).to have_received(:render_404)
      end
    end

    context 'when diff_file is found' do
      it 'renders the diff file component without layout' do
        controller_instance.diff_file

        expect(RapidDiffs::DiffFileComponent).to have_received(:new).with(
          diff_file: diff_file_double,
          parallel_view: false,
          plain_view: nil,
          environment: nil
        )
        expect(controller_instance).to have_received(:render).with(component_double, layout: false)
      end

      context 'with parallel view' do
        before do
          allow(controller_instance).to receive(:diff_view).and_return(:parallel)
        end

        it 'passes parallel_view: true to the component' do
          controller_instance.diff_file

          expect(RapidDiffs::DiffFileComponent).to have_received(:new).with(
            hash_including(parallel_view: true)
          )
        end
      end

      context 'with plain_view param present and true' do
        let(:params_hash) { { old_path: 'file.rb', new_path: 'file.rb', plain_view: 'true' } }

        it 'passes plain_view: true to the component' do
          controller_instance.diff_file

          expect(RapidDiffs::DiffFileComponent).to have_received(:new).with(
            hash_including(plain_view: true)
          )
        end
      end

      context 'with plain_view param present and false' do
        let(:params_hash) { { old_path: 'file.rb', new_path: 'file.rb', plain_view: 'false' } }

        it 'passes plain_view: false to the component' do
          controller_instance.diff_file

          expect(RapidDiffs::DiffFileComponent).to have_received(:new).with(
            hash_including(plain_view: false)
          )
        end
      end

      context 'with plain_view param not present' do
        let(:params_hash) { { old_path: 'file.rb', new_path: 'file.rb' } }

        it 'passes plain_view: nil to the component' do
          controller_instance.diff_file

          expect(RapidDiffs::DiffFileComponent).to have_received(:new).with(
            hash_including(plain_view: nil)
          )
        end
      end
    end

    context 'when file is whitespace_only and ignore_whitespace_changes is true' do
      let(:params_hash) { { old_path: 'file.rb', new_path: 'file.rb', ignore_whitespace_changes: 'true' } }
      let(:diff_file_double) do
        instance_double(Gitlab::Diff::File, whitespace_only?: true, blob: blob_double)
      end

      let(:non_whitespace_diff_file) do
        instance_double(Gitlab::Diff::File, whitespace_only?: false, blob: blob_double)
      end

      it 'refetches the diff file without ignoring whitespace' do
        call_count = 0
        allow(presenter_double).to receive(:diff_files) do
          call_count += 1
          if call_count == 1
            [diff_file_double]
          else
            [non_whitespace_diff_file]
          end
        end

        controller_instance.diff_file

        expect(call_count).to eq(2)
        expect(RapidDiffs::DiffFileComponent).to have_received(:new).with(
          hash_including(diff_file: non_whitespace_diff_file)
        )
      end
    end

    context 'when full param is true' do
      let(:params_hash) { { old_path: 'file.rb', new_path: 'file.rb', full: 'true' } }

      it 'calls expand_to_full! on the diff file' do
        expect(diff_file_double).to receive(:expand_to_full!)

        controller_instance.diff_file
      end

      context 'when blob is too large' do
        let(:blob_double) { instance_double(Blob, raw_size: 100_000) }

        it 'returns payload_too_large status' do
          controller_instance.diff_file

          expect(controller_instance).to have_received(:head).with(:payload_too_large)
        end
      end

      context 'when blob is nil' do
        let(:diff_file_double) do
          instance_double(Gitlab::Diff::File, whitespace_only?: false, blob: nil)
        end

        it 'does not return payload_too_large and expands to full' do
          expect(diff_file_double).to receive(:expand_to_full!)

          controller_instance.diff_file

          expect(controller_instance).not_to have_received(:head).with(:payload_too_large)
        end
      end
    end

    context 'when full param is not present' do
      let(:params_hash) { { old_path: 'file.rb', new_path: 'file.rb' } }

      it 'does not call expand_to_full!' do
        expect(diff_file_double).not_to receive(:expand_to_full!)

        controller_instance.diff_file
      end
    end

    context 'when full param is false' do
      let(:params_hash) { { old_path: 'file.rb', new_path: 'file.rb', full: 'false' } }

      it 'does not call expand_to_full!' do
        expect(diff_file_double).not_to receive(:expand_to_full!)

        controller_instance.diff_file
      end
    end
  end
end
