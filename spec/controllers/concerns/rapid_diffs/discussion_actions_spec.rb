# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RapidDiffs::DiscussionActions, feature_category: :source_code_management do
  subject(:controller) do
    Class.new(ApplicationController) do
      include RapidDiffs::DiscussionActions

      def call_rapid_diffs_enabled?
        rapid_diffs_enabled?
      end

      def call_noteable
        noteable
      end

      def call_create_note_params
        create_note_params
      end
    end
  end

  describe '#rapid_diffs_enabled?' do
    it 'raises NotImplementedError' do
      expect do
        controller.new.call_rapid_diffs_enabled?
      end.to raise_error(NotImplementedError, /must implement #rapid_diffs_enabled\?/)
    end
  end

  describe '#noteable' do
    it 'raises NotImplementedError' do
      expect do
        controller.new.call_noteable
      end.to raise_error(NotImplementedError, /must implement #noteable/)
    end
  end

  describe '#create_note_params' do
    it 'raises NotImplementedError' do
      expect do
        controller.new.call_create_note_params
      end.to raise_error(NotImplementedError, /must implement #create_note_params/)
    end
  end
end
