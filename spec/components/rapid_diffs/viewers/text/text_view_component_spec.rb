# frozen_string_literal: true

require "spec_helper"

RSpec.describe RapidDiffs::Viewers::Text::TextViewComponent, feature_category: :code_review_workflow do
  let_it_be(:diff_file) { build(:diff_file) }

  subject(:instance) { RapidDiffs::Viewers::Text::InlineViewComponent.new(diff_file: diff_file) }

  describe '#virtual_rendering_params' do
    it "returns an integer total_rows" do
      expect(instance.virtual_rendering_params[:total_rows]).to be_a(Integer)
    end
  end
end
