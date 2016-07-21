require 'spec_helper'

feature 'Diffs URL', js: true, feature: true do
  before do
    login_as :admin
    @merge_request = create(:merge_request)
    @project = @merge_request.source_project
  end

  context 'when visit with */* as accept header' do
    before(:each) do
      page.driver.add_header('Accept', '*/*')
    end

    it 'renders the notes' do
      create :note_on_merge_request, project: @project, noteable: @merge_request, note: 'Rebasing with master'

      visit diffs_namespace_project_merge_request_path(@project.namespace, @project, @merge_request)

      # Load notes and diff through AJAX
      expect(page).to have_css('.note-text', visible: false, text: 'Rebasing with master')
      expect(page).to have_css('.diffs.tab-pane.active')
    end
  end

  context 'when hovering over the parallel view diff file' do
    let(:comment_button_class) { '.add-diff-note' }

    before(:each) do
      visit diffs_namespace_project_merge_request_path(@project.namespace, @project, @merge_request)
      click_link 'Side-by-side'
      # @old_line_number = first '.diff-line-num.old_line:not(.empty-cell)'
      # @new_line_number = first '.diff-line-num.new_line:not(.empty-cell)'
      # @old_line = first '.line_content[data-line-type="old"]'
      # @new_line = first '.line_content[data-line-type="new"]'
    end

    context 'with an old line on the left and no line on the right' do
      it 'should allow commenting on the left side' do
        puts first('//*[contains(concat(" ", @class, " "), " line_holder ") and child::*[contains(concat(" ", @class, " "), " line_content ") and contains(concat(" ", @class, " "), " old ")] and child::*[contains(concat(" ", @class, " ")," line_content ") and contains(concat(" ", @class, " ")," new ")]]')
        expect(page).to have_content 'NOPE'
      end

      it 'should not allow commenting on the right side' do

      end
    end

    context 'with no line on the left and a new line on the right' do
      it 'should allow commenting on the right side' do

      end

      it 'should not allow commenting on the left side' do

      end
    end

    context 'with an old line on the left and a new line on the right' do
      it 'should allow commenting on the left side' do

      end

      it 'should allow commenting on the right side' do

      end
    end

    context 'with an unchanged line on the left and an unchanged line on the right' do
      it 'should allow commenting on the left side' do

      end

      it 'should allow commenting on the right side' do

      end
    end

    context 'with a match line' do
      it 'should not allow commenting on the left side' do

      end

      it 'should not allow commenting on the right side' do

      end
    end

    # it 'shows a comment button on the old side when hovering over an old line number' do
    #   @old_line_number.hover
    #   expect(@old_line_number).to have_css comment_button_class
    #   expect(@new_line_number).not_to have_css comment_button_class
    # end
    #
    # it 'shows a comment button on the old side when hovering over an old line' do
    #   @old_line.hover
    #   expect(@old_line_number).to have_css comment_button_class
    #   expect(@new_line_number).not_to have_css comment_button_class
    # end
    #
    # it 'shows a comment button on the new side when hovering over a new line number' do
    #   @new_line_number.hover
    #   expect(@new_line_number).to have_css comment_button_class
    #   expect(@old_line_number).not_to have_css comment_button_class
    # end
    #
    # it 'shows a comment button on the new side when hovering over a new line' do
    #   @new_line.hover
    #   expect(@new_line_number).to have_css comment_button_class
    #   expect(@old_line_number).not_to have_css comment_button_class
    # end
  end

  context 'when hovering over the inline view diff file' do
    let(:comment_button_class) { '.add-diff-note' }

    before(:each) do
      visit diffs_namespace_project_merge_request_path(@project.namespace, @project, @merge_request)
      click_link 'Inline'
      # @old_line_number = first '.diff-line-num.old_line:not(.unfold)'
      # @new_line_number = first '.diff-line-num.new_line:not(.unfold)'
      # @new_line = first '.line_content:not(.match)'
    end

    context 'with a new line' do
      it 'should allow commenting' do

      end
    end

    context 'with an old line' do
      it 'should allow commenting' do

      end
    end

    context 'with an unchanged line' do
      it 'should allow commenting' do

      end
    end

    context 'with a match line' do
      it 'should not allow commenting' do

      end
    end

    # it 'shows a comment button on the old side when hovering over an old line number' do
    #   @old_line_number.hover
    #   expect(@old_line_number).to have_css comment_button_class
    #   expect(@new_line_number).not_to have_css comment_button_class
    # end
    #
    # it 'shows a comment button on the new side when hovering over a new line number' do
    #   @new_line_number.hover
    #   expect(@old_line_number).to have_css comment_button_class
    #   expect(@new_line_number).not_to have_css comment_button_class
    # end
    #
    # it 'shows a comment button on the new side when hovering over a new line' do
    #   @new_line.hover
    #   expect(@old_line_number).to have_css comment_button_class
    #   expect(@new_line_number).not_to have_css comment_button_class
    # end
  end

  # context 'when clicking a comment button' do
  #   let(:test_note_comment) { 'this is a test note!' }
  #   let(:note_class) { '.new-note' }
  #
  #   before(:each) do
  #     visit diffs_namespace_project_merge_request_path(@project.namespace, @project, @merge_request)
  #     click_link 'Inline'
  #     first('.diff-line-num.old_line:not(.unfold)').hover
  #     find('.add-diff-note').click
  #   end
  #
  #   it 'shows a note form' do
  #     expect(page).to have_css note_class
  #   end
  #
  #   it 'can be submitted and viewed' do
  #     fill_in 'note[note]', with: test_note_comment
  #     click_button 'Comment'
  #     expect(page).to have_content test_note_comment
  #   end
  #
  #   it 'can be closed' do
  #     find('.note-form-actions .btn-cancel').click
  #     expect(page).not_to have_css note_class
  #   end
  # end
end
