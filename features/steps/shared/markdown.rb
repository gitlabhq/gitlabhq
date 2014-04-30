module SharedMarkdown
  include Spinach::DSL

  protected

  # Header anchors

  def header_should_have_correct_id_and_link(level, text, id, parent = '.wiki')
    page.find("#{parent} h#{level}##{id}").text.should == text
    page.find("#{parent} h#{level}##{id} > :last-child")[:href]
      .should =~ /##{id}$/
  end

  def header_should_not_have_id(level = 1, parent = '.wiki')
    within(parent) do
      find("h#{level}")[:id].should == nil
    end
  end

  def preview_header_should_have_id(within_selector = 'body')
    within(within_selector) do
      header_should_have_correct_id_and_link(1, '# Header',
                                             'header', '.js-gfm-preview')
    end
  end

  def preview_header_should_not_have_id(within_selector = 'body')
    within(within_selector) do
      header_should_not_have_id(1, '.js-gfm-preview')
    end
  end

  # Preview

  def markdown_preview_button_should_be_enabled(within_selector, enabled = true)
    within(within_selector) do
      if enabled
        find('.js-gfm-preview-button', visible: true)[:disabled].should == nil
      else
        find('.js-gfm-preview-button', visible: true)[:disabled]
          .should == 'disabled'
      end
    end
  end

  def should_see_markdown_edit_button(within_selector, visible = true)
    within(within_selector) do
      if visible
        page.should have_css('.js-gfm-edit-button', visible: true)
      else
        page.should_not have_css('.js-gfm-edit-button', visible: true)
      end
    end
  end

  def click_markdown_edit_button(within_selector = 'body')
    within(within_selector) do
      find('.js-gfm-edit-button', visible: true).click
    end
  end

  def should_see_the_markdown_preview(within_selector, visible = true)
    within(within_selector) do
      if visible
        page.should have_css('.js-gfm-preview', visible: true)
      else
        page.should_not have_css('.js-gfm-preview', visible: true)
      end
    end
  end

  def should_see_the_markdown_input(within_selector, visible = true)
    within(within_selector) do
      if visible
        page.should have_css('.js-gfm-input', visible: true)
      else
        page.should_not have_css('.js-gfm-input', visible: true)
      end
    end
  end

  def click_markdown_preview_button(within_selector = 'body')
    within(within_selector) do
      find('.js-gfm-preview-button').click
    end
  end

  def preview_markdown_with(within_selector, input)
    within(within_selector) do
      find('.js-gfm-input').set(input)
      find('.js-gfm-preview-button').click
    end
  end

  def preview_markdown_with_header(within_selector = 'body')
    preview_markdown_with(within_selector, '# Header')
  end

  def input_should_be_header_input(within_selector = 'body')
    within(within_selector) do
      find('.js-gfm-input').value.should == '# Header'
    end
  end
end
