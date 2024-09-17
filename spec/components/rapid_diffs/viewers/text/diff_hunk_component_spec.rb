# frozen_string_literal: true

require "spec_helper"

RSpec.describe RapidDiffs::Viewers::Text::DiffHunkComponent, type: :component, feature_category: :code_review_workflow do
  let_it_be(:diff_file) { build(:diff_file) }

  describe '#expand_buttons' do
    it { expect { create_component.expand_buttons }.to raise_error(NotImplementedError) }
  end

  def create_component
    described_class.new(diff_file: diff_file, diff_hunk: { lines: [] })
  end
end
