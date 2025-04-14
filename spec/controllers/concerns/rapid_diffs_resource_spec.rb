# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RapidDiffsResource, type: :controller, feature_category: :source_code_management do
  subject(:controller) do
    Class.new(ApplicationController) do
      include RapidDiffsResource

      def call_diffs_stream_resource_url(resource, offset, diff_view)
        diffs_stream_resource_url(resource, offset, diff_view)
      end

      def call_diffs_stream_url(resource, offset, diff_view)
        diffs_stream_url(resource, offset, diff_view)
      end

      def call_diffs_resource
        diffs_resource
      end

      def call_complete_diff_path
        complete_diff_path
      end

      def call_email_format_path
        email_format_path
      end
    end
  end

  let_it_be(:offset) { 5 }
  let_it_be(:diff_view) { :inline }
  let_it_be(:sha) { "913c66a37b4a45b9769037c55c2d238bd0942d2e" }
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:commit) { project.commit_by(oid: sha) }

  describe '#diffs_stream_resource_url' do
    it 'raises NotImplementedError' do
      expect do
        controller.new.call_diffs_stream_resource_url(commit, offset, diff_view)
      end.to raise_error(NotImplementedError)
    end
  end

  describe '#diffs_stream_url' do
    context 'when offset is greater than the number of diffs' do
      let_it_be(:offset) { 9999 }

      it 'returns nil' do
        expect(controller.new.call_diffs_stream_url(commit, offset, diff_view)).to be_nil
      end
    end
  end

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
end
