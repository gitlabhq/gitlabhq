# frozen_string_literal: true

require "spec_helper"

RSpec.describe RapidDiffs::Viewers::ViewerComponent, type: :component, feature_category: :code_review_workflow do
  describe '#viewer_name' do
    it { expect { described_class.viewer_name }.to raise_error(NotImplementedError) }
  end
end
