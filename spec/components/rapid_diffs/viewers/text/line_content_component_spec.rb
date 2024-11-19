# frozen_string_literal: true

require "spec_helper"

RSpec.describe RapidDiffs::Viewers::Text::LineContentComponent, type: :component, feature_category: :code_review_workflow do
  let_it_be(:diff_file) { build(:diff_file) }
  let_it_be(:old_line) { diff_file.diff_lines_with_match_tail.find { |line| line.type == 'old' } }
  let_it_be(:new_line) { diff_file.diff_lines_with_match_tail.find { |line| line.type == 'new' } }

  it 'renders added line' do
    allow(new_line).to receive_messages(added?: true, removed?: false)
    render_component(line: new_line, position: :new)
    selector = 'td[data-change="added"][data-position="new"]'
    expect(page).to have_selector(selector, text: new_line.text[1..], normalize_ws: false)
  end

  it 'renders removed line' do
    allow(old_line).to receive_messages(removed?: true, added?: false)
    render_component(line: old_line, position: :old)
    selector = 'td[data-change="removed"][data-position="old"]'
    expect(page).to have_selector(selector, text: old_line.text[1..], normalize_ws: false)
  end

  it 'renders unchanged line' do
    allow(old_line).to receive_messages(added?: false, removed?: false)
    render_component(line: old_line, position: :old)
    expect(page).to have_selector('td[data-position="old"]', text: old_line.text[1..], normalize_ws: false)
  end

  it 'renders empty cell' do
    render_component(line: nil, position: :old)
    expect(page).to have_selector('td[data-position="old"]')
  end

  def render_component(line:, position: nil)
    render_inline(described_class.new(line: line, position: position))
  end
end
