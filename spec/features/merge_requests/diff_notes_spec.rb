require 'spec_helper'

feature 'Diff notes', js: true, feature: true do
  include WaitForAjax

  before do
    login_as :admin
    @merge_request = create(:merge_request)
    @project = @merge_request.source_project
  end

  context 'merge request diffs' do
    let(:comment_button_class) { '.add-diff-note' }
    let(:notes_holder_input_class) { 'js-temp-notes-holder' }
    let(:notes_holder_input_xpath) { './following-sibling::*[contains(concat(" ", @class, " "), " notes_holder ")]' }
    let(:test_note_comment) { 'this is a test note!' }

    context 'when hovering over the parallel view diff file' do
      before(:each) do
        visit diffs_namespace_project_merge_request_path(@project.namespace, @project, @merge_request)
        click_link 'Side-by-side'
      end

      context 'with an old line on the left and no line on the right' do
        it 'should allow commenting on the left side' do
          should_allow_commenting(find('[id="6eb14e00385d2fb284765eb1cd8d420d33d63fc9_23_22"]').find(:xpath, '..'), 'left')
        end

        it 'should not allow commenting on the right side' do
          should_not_allow_commenting(find('[id="6eb14e00385d2fb284765eb1cd8d420d33d63fc9_23_22"]').find(:xpath, '..'), 'right')
        end
      end

      context 'with no line on the left and a new line on the right' do
        it 'should not allow commenting on the left side' do
          should_not_allow_commenting(find('[id="2f6fcd96b88b36ce98c38da085c795a27d92a3dd_15_15"]').find(:xpath, '..'), 'left')
        end

        it 'should allow commenting on the right side' do
          should_allow_commenting(find('[id="2f6fcd96b88b36ce98c38da085c795a27d92a3dd_15_15"]').find(:xpath, '..'), 'right')
        end
      end

      context 'with an old line on the left and a new line on the right' do
        it 'should allow commenting on the left side' do
          should_allow_commenting(find('[id="2f6fcd96b88b36ce98c38da085c795a27d92a3dd_9_9"]').find(:xpath, '..'), 'left')
        end

        it 'should allow commenting on the right side' do
          should_allow_commenting(find('[id="2f6fcd96b88b36ce98c38da085c795a27d92a3dd_9_9"]').find(:xpath, '..'), 'right')
        end
      end

      context 'with an unchanged line on the left and an unchanged line on the right' do
        it 'should allow commenting on the left side' do
          should_allow_commenting(first('[id="2f6fcd96b88b36ce98c38da085c795a27d92a3dd_7_7"]').find(:xpath, '..'), 'left')
        end

        it 'should allow commenting on the right side' do
          should_allow_commenting(first('[id="2f6fcd96b88b36ce98c38da085c795a27d92a3dd_7_7"]').find(:xpath, '..'), 'right')
        end
      end

      context 'with a match line' do
        it 'should not allow commenting on the left side' do
          should_not_allow_commenting(first('.match').find(:xpath, '..'), 'left')
        end

        it 'should not allow commenting on the right side' do
          should_not_allow_commenting(first('.match').find(:xpath, '..'), 'right')
        end
      end
    end

    context 'when hovering over the inline view diff file' do
      before do
        visit diffs_namespace_project_merge_request_path(@project.namespace, @project, @merge_request)
        click_link 'Inline'
      end

      context 'with a new line' do
        it 'should allow commenting' do
          should_allow_commenting(find('[id="2f6fcd96b88b36ce98c38da085c795a27d92a3dd_10_9"]'))
        end
      end

      context 'with an old line' do
        it 'should allow commenting' do
          should_allow_commenting(find('[id="6eb14e00385d2fb284765eb1cd8d420d33d63fc9_22_22"]'))
        end
      end

      context 'with an unchanged line' do
        it 'should allow commenting' do
          should_allow_commenting(find('[id="2f6fcd96b88b36ce98c38da085c795a27d92a3dd_7_7"]'))
        end
      end

      context 'with a match line' do
        it 'should not allow commenting' do
          should_not_allow_commenting(first('.match'))
        end
      end
    end

    def should_allow_commenting(line_holder, diff_side = nil)
      line = get_line_components(line_holder, diff_side)
      line[:content].hover
      expect(line[:num]).to have_css comment_button_class

      comment_on_line(line_holder, line)
      wait_for_ajax

      assert_comment_persistence(line_holder)
    end

    def should_not_allow_commenting(line_holder, diff_side = nil)
      line = get_line_components(line_holder, diff_side)
      line[:content].hover
      expect(line[:num]).not_to have_css comment_button_class
    end

    def get_line_components(line_holder, diff_side = nil)
      if diff_side.nil?
        get_inline_line_components(line_holder)
      else
        get_parallel_line_components(line_holder, diff_side)
      end
    end

    def get_inline_line_components(line_holder)
      { content: line_holder.first('.line_content'), num: line_holder.first('.diff-line-num') }
    end

    def get_parallel_line_components(line_holder, diff_side = nil)
      side_index = diff_side == 'left' ? 0 : 1
      { content: line_holder.all('.line_content')[side_index], num: line_holder.all('.diff-line-num')[side_index] }
    end

    def comment_on_line(line_holder, line)
      line[:num].find(comment_button_class).trigger 'click'
      expect(line_holder).to have_xpath notes_holder_input_xpath

      notes_holder_input = line_holder.find(:xpath, notes_holder_input_xpath)
      expect(notes_holder_input[:class]).to include(notes_holder_input_class)

      notes_holder_input.fill_in 'note[note]', with: test_note_comment
      click_button 'Comment'
    end

    def assert_comment_persistence(line_holder)
      expect(line_holder).to have_xpath notes_holder_input_xpath

      notes_holder_saved = line_holder.find(:xpath, notes_holder_input_xpath)
      expect(notes_holder_saved[:class]).not_to include(notes_holder_input_class)
      expect(notes_holder_saved).to have_content test_note_comment
    end
  end
end
