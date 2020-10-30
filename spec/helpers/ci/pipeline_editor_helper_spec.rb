# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::PipelineEditorHelper do
  let_it_be(:project) { create(:project) }

  describe 'can_view_pipeline_editor?' do
    subject { helper.can_view_pipeline_editor?(project) }

    it 'user can view editor if they can collaborate' do
      allow(helper).to receive(:can_collaborate_with_project?).and_return(true)

      expect(subject).to be true
    end

    it 'user can not view editor if they cannot collaborate' do
      allow(helper).to receive(:can_collaborate_with_project?).and_return(false)

      expect(subject).to be false
    end

    it 'user can not view editor if feature is disabled' do
      allow(helper).to receive(:can_collaborate_with_project?).and_return(true)
      stub_feature_flags(ci_pipeline_editor_page: false)

      expect(subject).to be false
    end
  end
end
