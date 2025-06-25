# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RapidDiffs::Resource, type: :controller, feature_category: :source_code_management do
  subject(:controller) do
    Class.new(ApplicationController) do
      include RapidDiffs::Resource

      def call_diffs_resource
        diffs_resource
      end

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
    end
  end

  let_it_be(:offset) { 5 }
  let_it_be(:diff_view) { :inline }
  let_it_be(:sha) { "913c66a37b4a45b9769037c55c2d238bd0942d2e" }
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:commit) { project.commit_by(oid: sha) }

  describe '#diffs_resource' do
    it 'raises NotImplementedError' do
      expect do
        controller.new.call_diffs_resource
      end.to raise_error(NotImplementedError)
    end
  end

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
      args = { parallel_view: :parallel }

      expect(RapidDiffs::DiffFileComponent).to receive(:new).with(**args)

      controller.new.call_diff_file_component(args)
    end
  end

  describe '#find_diff_file' do
    let(:controller_instance) { controller.new }
    let(:diff_file) { instance_double(Gitlab::Git::Diff) }
    let(:diff_files) { [diff_file] }
    let(:diffs_resource) { instance_double(Gitlab::Diff::FileCollection::Base, diff_files: diff_files) }
    let(:extra_options) { { expanded: true } }
    let(:old_path) { 'old_path.rb' }
    let(:new_path) { 'new_path.rb' }

    before do
      allow(controller_instance).to receive(:diffs_resource).with(
        hash_including(paths: [old_path, new_path], expanded: true)
      ).and_return(diffs_resource)
    end

    it 'calls diffs_resource with merged options and returns the first diff file' do
      expect(controller_instance.call_find_diff_file(extra_options, old_path, new_path)).to eq(diff_file)
    end
  end
end
