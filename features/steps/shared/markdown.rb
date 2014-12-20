module SharedMarkdown
  include Spinach::DSL

  def header_should_have_correct_id_and_link(level, text, id, parent = ".wiki")
    find(:css, "#{parent} h#{level}##{id}").text.should == text
    find(:css, "#{parent} h#{level}##{id} > :last-child")[:href].should =~ /##{id}$/
  end

  def create_taskable(type, title)
    desc_text = <<EOT.gsub(/^ {6}/, '')
      * [ ] Task 1
      * [x] Task 2
EOT

    case type
    when :issue, :closed_issue
      options = { project: project }
    when :merge_request
      options = { source_project: project, target_project: project }
    end

    create(
      type,
      options.merge(title: title,
                    author: project.users.first,
                    description: desc_text)
    )
  end

  step 'Header "Description header" should have correct id and link' do
    header_should_have_correct_id_and_link(1, 'Description header', 'description-header')
  end

  step 'I should see task checkboxes in the description' do
    expect(page).to have_selector(
      'div.description li.task-list-item input[type="checkbox"]'
    )
  end

  step 'I should see the task status for the Taskable' do
    expect(find(:css, 'span.task-status').text).to eq(
      '2 tasks (1 done, 1 unfinished)'
    )
  end

  step 'Task checkboxes should be enabled' do
    expect(page).to have_selector(
      'div.description li.task-list-item input[type="checkbox"]:enabled'
    )
  end

  step 'Task checkboxes should be disabled' do
    expect(page).to have_selector(
      'div.description li.task-list-item input[type="checkbox"]:disabled'
    )
  end

  step 'I should not see the Markdown preview' do
    expect(find('.gfm-form .js-md-preview')).not_to be_visible
  end

  step 'The Markdown preview tab should say there is nothing to do' do
    within('.gfm-form') do
      find('.js-md-preview-button').click
      expect(find('.js-md-preview')).to have_content('Nothing to preview.')
    end
  end

  step 'I should not see the Markdown text field' do
    expect(find('.gfm-form textarea')).not_to be_visible
  end

  step 'I should see the Markdown write tab' do
    expect(find('.gfm-form')).to have_css('.js-md-write-button', visible: true)
  end

  step 'I should see the Markdown preview' do
    expect(find('.gfm-form')).to have_css('.js-md-preview', visible: true)
  end

  step 'The Markdown preview tab should display rendered Markdown' do
    within('.gfm-form') do
      find('.js-md-preview-button').click
      expect(find('.js-md-preview')).to have_css('img.emoji', visible: true)
    end
  end

  step 'I write a description like ":+1: Nice"' do
    find('.gfm-form').fill_in 'Description', with: ':+1: Nice'
  end

  step 'I preview a description text like "Bug fixed :smile:"' do
    within('.gfm-form') do
      fill_in 'Description', with: 'Bug fixed :smile:'
      find('.js-md-preview-button').click
    end
  end

  step 'I haven\'t written any description text' do
    find('.gfm-form').fill_in 'Description', with: ''
  end
end
