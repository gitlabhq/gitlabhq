# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Merge request > Rapid Diffs > Linked expanded line', :js, feature_category: :code_review_workflow do
  let_it_be(:project) { create(:project, :public, :repository) }
  let_it_be(:merge_request) { create(:merge_request, source_project: project, target_project: project) }

  # Follows the real flow inside the given file: expand a folded region, then
  # read the copy link the UI attaches to a revealed line. Everything is read
  # from the rendered page. Returns [row_id, copied_href].
  def expand_and_copy_linked_line(file_id)
    all(%(diff-file[id="#{file_id}"] button[data-expand-direction]), minimum: 1).last.click
    expect(page).to have_css(%(diff-file[id="#{file_id}"] tr[data-expanded]), wait: 20)

    row = find(%(diff-file[id="#{file_id}"])).all('tr[data-expanded]').last
    [row[:id], row.first('[data-line-number]')['href']]
  end

  before do
    visit diffs_project_merge_request_path(project, merge_request, rapid_diffs: true)
  end

  it 'expands the linked line after following its copied link', :aggregate_failures do
    file_id = find('button[data-expand-direction]', match: :first).ancestor('diff-file')[:id]

    line_id, href = expand_and_copy_linked_line(file_id)

    expect(href).to include("line=#{line_id}")

    visit href

    expect(page).to have_css("##{line_id}")
  end

  context 'when the file also has a discussion on an expanded line' do
    let(:discussion_file) { 'files/ruby/popen.rb' }
    let(:discussion_line) { 1 }
    let!(:discussion) do
      create(:diff_note_on_merge_request, :folded_position, project: project, noteable: merge_request)
    end

    it 'expands both the discussion line and the linked line', :aggregate_failures do
      file_id = find('diff-file', text: discussion_file, match: :first)[:id]

      line_id, href = expand_and_copy_linked_line(file_id)

      visit href

      expect(page).to have_css("##{line_id}")
      expect(page).to have_css("##{line_id.sub(/_\d+\z/, "_#{discussion_line}")}")
    end
  end
end
