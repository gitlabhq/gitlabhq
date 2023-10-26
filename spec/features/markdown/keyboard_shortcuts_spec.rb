# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Markdown keyboard shortcuts', :js, feature_category: :team_planning do
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:user) { create(:user) }

  let(:is_mac) { page.evaluate_script('navigator.platform').include?('Mac') }
  let(:modifier_key) { is_mac ? :command : :control }
  let(:other_modifier_key) { is_mac ? :control : :command }

  before do
    project.add_developer(user)

    gitlab_sign_in(user)

    visit path_to_visit

    wait_for_requests
  end

  shared_examples 'keyboard shortcuts' do
    it 'bolds text when <modifier>+B is pressed' do
      type_and_select('bold')

      markdown_field.send_keys([modifier_key, 'b'])

      expect(markdown_field.value).to eq('**bold**')
    end

    it 'italicizes text when <modifier>+I is pressed' do
      type_and_select('italic')

      markdown_field.send_keys([modifier_key, 'i'])

      expect(markdown_field.value).to eq('_italic_')
    end

    it 'strikes text when <modifier>+<shift>+x is pressed' do
      type_and_select('strikethrough')

      markdown_field.send_keys([modifier_key, :shift, 'x'])

      expect(markdown_field.value).to eq('~~strikethrough~~')
    end

    it 'links text when <modifier>+K is pressed' do
      type_and_select('link')

      markdown_field.send_keys([modifier_key, 'k'])

      expect(markdown_field.value).to eq('[link](url)')

      # Type some more text to ensure the cursor
      # and selection are set correctly
      markdown_field.send_keys('https://example.com')

      expect(markdown_field.value).to eq('[link](https://example.com)')
    end

    it 'does not affect non-markdown fields on the same page' do
      non_markdown_field.send_keys('some text')

      non_markdown_field.send_keys([modifier_key, 'b'])

      expect(focused_element).to eq(non_markdown_field.native)
      expect(markdown_field.value).to eq('')
    end
  end

  shared_examples 'no side effects' do
    it 'does not bold text when <other modifier>+B is pressed' do
      type_and_select('bold')

      markdown_field.send_keys([@other_modifier_key, 'b'])

      expect(markdown_field.value).not_to eq('**bold**')
    end

    it 'does not italicize text when <other modifier>+I is pressed' do
      type_and_select('italic')

      markdown_field.send_keys([@other_modifier_key, 'i'])

      expect(markdown_field.value).not_to eq('_italic_')
    end

    it 'does not link text when <other modifier>+K is pressed' do
      type_and_select('link')

      markdown_field.send_keys([@other_modifier_key, 'k'])

      expect(markdown_field.value).not_to eq('[link](url)')
    end
  end

  context 'Vue.js markdown editor' do
    let(:path_to_visit) { new_project_release_path(project) }
    let(:markdown_field) { find_field('release-notes') }
    let(:non_markdown_field) { find_field('release-title') }

    it_behaves_like 'keyboard shortcuts'
    it_behaves_like 'no side effects'

    context 'if preview is toggled before shortcuts' do
      before do
        click_button "Preview"
        click_button "Continue editing"
      end

      it_behaves_like 'keyboard shortcuts'
      it_behaves_like 'no side effects'
    end
  end

  def type_and_select(text)
    markdown_field.send_keys(text)

    text.length.times do
      markdown_field.send_keys([:shift, :arrow_left])
    end
  end

  def focused_element
    page.driver.browser.switch_to.active_element
  end
end
