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
end
