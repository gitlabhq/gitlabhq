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

  context 'diff notes' do
    let(:comment_button_class) { '.add-diff-note' }
    let(:notes_holder_input_class) { 'js-temp-notes-holder' }
    let(:notes_holder_input_xpath) { './following-sibling::*[contains(concat(" ", @class, " "), " notes_holder ")]' }
    let(:test_note_comment) { 'this is a test note!' }
    # line_holder = //*[contains(concat(" ", @class, " "), " line_holder "]
    # old_line = child::*[contains(concat(" ", @class, " "), " line_content ") and contains(concat(" ", @class, " "), " old ")]
    # new_line = child::*[contains(concat(" ", @class, " ")," line_content ") and contains(concat(" ", @class, " ")," new ")]
    # match_line = child::*[contains(concat(" ", @class, " ")," line_content ") and contains(concat(" ", @class, " ")," match ")]
    # unchanged_line = child::*[contains(concat(" ", @class, " ")," line_content ") and not(contains(concat(" ", @class, " ")," old ")) and not(contains(concat(" ", @class, " ")," new ")) and not(contains(concat(" ", @class, " ")," match ")) and boolean(node()[1])]
    # no_line = child::*[contains(concat(" ", @class, " ")," line_content ") and not(contains(concat(" ", @class, " ")," old ")) and not(contains(concat(" ", @class, " ")," new ")) and not(contains(concat(" ", @class, " ")," match ")) and not(boolean(node()[1]))]

    context 'when hovering over the parallel view diff file' do
      before(:each) do
        visit diffs_namespace_project_merge_request_path(@project.namespace, @project, @merge_request)
        click_link 'Side-by-side'
      end

      context 'with an old line on the left and no line on the right' do
        let(:line_holder) { first :xpath, '//*[contains(concat(" ", @class, " "), " line_holder ") and child::*[contains(concat(" ", @class, " "), " line_content ") and contains(concat(" ", @class, " "), " old ")] and child::*[contains(concat(" ", @class, " ")," line_content ") and not(contains(concat(" ", @class, " ")," old ")) and not(contains(concat(" ", @class, " ")," new ")) and not(contains(concat(" ", @class, " ")," match ")) and not(boolean(node()[1]))]]' }

        it 'should allow commenting on the left side' do
          should_allow_commenting line_holder, 'left'
        end

        it 'should not allow commenting on the right side' do
          should_not_allow_commenting line_holder, 'right'
        end
      end

      context 'with no line on the left and a new line on the right' do
        let(:line_holder) { first :xpath, '//*[contains(concat(" ", @class, " "), " line_holder ") and child::*[contains(concat(" ", @class, " ")," line_content ") and not(contains(concat(" ", @class, " ")," old ")) and not(contains(concat(" ", @class, " ")," new ")) and not(contains(concat(" ", @class, " ")," match ")) and not(boolean(node()[1]))] and child::*[contains(concat(" ", @class, " ")," line_content ") and contains(concat(" ", @class, " ")," new ")]]' }

        it 'should not allow commenting on the left side' do
          should_not_allow_commenting line_holder, 'left'
        end

        it 'should allow commenting on the right side' do
          should_allow_commenting line_holder, 'right'
        end
      end

      context 'with an old line on the left and a new line on the right' do
        let(:line_holder) { first :xpath, '//*[contains(concat(" ", @class, " "), " line_holder ") and child::*[contains(concat(" ", @class, " "), " line_content ") and contains(concat(" ", @class, " "), " old ")] and child::*[contains(concat(" ", @class, " ")," line_content ") and contains(concat(" ", @class, " ")," new ")]]' }

        it 'should allow commenting on the left side' do
          should_allow_commenting line_holder, 'left'
        end

        it 'should allow commenting on the right side' do
          should_allow_commenting line_holder, 'right'
        end
      end

      context 'with an unchanged line on the left and an unchanged line on the right' do
        let(:line_holder) { first :xpath, '//*[contains(concat(" ", @class, " "), " line_holder ") and child::*[contains(concat(" ", @class, " ")," line_content ") and not(contains(concat(" ", @class, " ")," old ")) and not(contains(concat(" ", @class, " ")," new ")) and not(contains(concat(" ", @class, " ")," match ")) and boolean(node()[1])] and child::*[contains(concat(" ", @class, " ")," line_content ") and not(contains(concat(" ", @class, " ")," old ")) and not(contains(concat(" ", @class, " ")," new ")) and not(contains(concat(" ", @class, " ")," match ")) and boolean(node()[1])]]' }

        it 'should allow commenting on the left side' do
          should_allow_commenting line_holder, 'left'
        end

        it 'should allow commenting on the right side' do
          should_allow_commenting line_holder, 'right'
        end
      end

      context 'with a match line' do
        let(:line_holder) { first :xpath, '//*[contains(concat(" ", @class, " "), " line_holder ") and child::*[contains(concat(" ", @class, " "), " line_content ") and contains(concat(" ", @class, " "), " match ")] and child::*[contains(concat(" ", @class, " ")," line_content ") and contains(concat(" ", @class, " ")," match ")]]' }

        it 'should not allow commenting on the left side' do
          should_not_allow_commenting line_holder, 'left'
        end

        it 'should not allow commenting on the right side' do
          should_not_allow_commenting line_holder, 'right'
        end
      end
    end

    context 'when hovering over the inline view diff file' do
      let(:comment_button_class) { '.add-diff-note' }

      before(:each) do
        visit diffs_namespace_project_merge_request_path(@project.namespace, @project, @merge_request)
        click_link 'Inline'
      end

      context 'with a new line' do
        let(:line_holder) { first :xpath, '//*[contains(concat(" ", @class, " "), " line_holder ") and child::*[contains(concat(" ", @class, " "), " line_content ") and contains(concat(" ", @class, " "), " new ")]]' }

        it 'should allow commenting' do
          should_allow_commenting line_holder
        end
      end

      context 'with an old line' do
        let(:line_holder) { first :xpath, '//*[contains(concat(" ", @class, " "), " line_holder ") and child::*[contains(concat(" ", @class, " "), " line_content ") and contains(concat(" ", @class, " "), " old ")]]' }

        it 'should allow commenting' do
          should_allow_commenting line_holder
        end
      end

      context 'with an unchanged line' do
        let(:line_holder) { first :xpath, '//*[contains(concat(" ", @class, " "), " line_holder ") and child::*[contains(concat(" ", @class, " ")," line_content ") and not(contains(concat(" ", @class, " ")," old ")) and not(contains(concat(" ", @class, " ")," new ")) and not(contains(concat(" ", @class, " ")," match ")) and boolean(node()[1])] and child::*[contains(concat(" ", @class, " ")," line_content ") and not(contains(concat(" ", @class, " ")," old ")) and not(contains(concat(" ", @class, " ")," new ")) and not(contains(concat(" ", @class, " ")," match ")) and boolean(node()[1])]]' }

        it 'should allow commenting' do
          should_allow_commenting line_holder
        end
      end

      context 'with a match line' do
        let(:line_holder) { first :xpath, '//*[contains(concat(" ", @class, " "), " line_holder ") and child::*[contains(concat(" ", @class, " "), " line_content ") and contains(concat(" ", @class, " "), " match ")]]' }

        it 'should not allow commenting' do
          should_not_allow_commenting line_holder
        end
      end
    end

    def should_allow_commenting(line_holder, diff_side = nil)
      line = get_line diff_side
      line[:content].hover
      expect(line[:num]).to have_css comment_button_class
      line[:num].find(comment_button_class).trigger 'click'
      expect(line_holder).to have_xpath notes_holder_input_xpath
      notes_holder_input = line_holder.find(:xpath, notes_holder_input_xpath)
      expect(notes_holder_input[:class].include? notes_holder_input_class).to be true
      notes_holder_input.fill_in 'note[note]', with: test_note_comment
      click_button 'Comment'
      expect(line_holder).to have_xpath notes_holder_input_xpath
      notes_holder_saved = line_holder.find(:xpath, notes_holder_input_xpath)
      expect(notes_holder_saved[:class].include? notes_holder_input_class).to be false
      expect(notes_holder_saved).to have_content test_note_comment
    end

    def should_not_allow_commenting(line_holder, diff_side = nil)
      line = get_line diff_side
      line[:content].hover
      expect(line[:num]).not_to have_css comment_button_class
    end

    def get_line(diff_side = nil)
      if diff_side.nil?
        { content: line_holder.first('.line_content'), num: line_holder.first('.diff-line-num') }
      else
        side_index = diff_side == 'left' ? 0 : 1
        { content: line_holder.all('.line_content')[side_index], num: line_holder.all('.diff-line-num')[side_index] }
      end
    end
  end
end
