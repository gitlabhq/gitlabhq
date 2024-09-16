# frozen_string_literal: true

require "spec_helper"

RSpec.describe RapidDiffs::Viewers::Text::TextViewComponent, type: :component, feature_category: :code_review_workflow do
  let_it_be(:diff_file) { build(:diff_file) }

  describe '#lines' do
    it { delegates_implementation_for { create_component.lines } }
  end

  describe '#diff_line' do
    it { delegates_implementation_for { create_component.diff_line(diff_file.highlighted_diff_lines.first) } }
  end

  describe '#hunk_view_component' do
    it { delegates_implementation_for { create_component.hunk_view_component } }
  end

  describe '#column_titles' do
    it { delegates_implementation_for { create_component.column_titles } }
  end

  def delegates_implementation_for
    expect { yield }.to raise_error(NotImplementedError)
  end

  def create_component
    described_class.new(diff_file: diff_file)
  end
end
