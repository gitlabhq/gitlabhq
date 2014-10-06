module SharedMarkdown
  include Spinach::DSL

  def header_should_have_correct_id_and_link(level, text, id, parent = ".wiki")
    find(:css, "#{parent} h#{level}##{id}").text.should == text
    find(:css, "#{parent} h#{level}##{id} > :last-child")[:href].should =~ /##{id}$/
  end

  step 'Header "Description header" should have correct id and link' do
    header_should_have_correct_id_and_link(1, 'Description header', 'description-header')
  end

  step 'I should see task checkboxes in the description' do
    expect(page).to have_selector(
      'div.description li.task-list-item input[type="checkbox"]'
    )
  end

  step 'I should see the task status for issue "Tasks-open"' do
    expect(find(:css, 'span.task-status').text).to eq(
      '2 tasks (1 done, 1 unfinished)'
    )
  end

  step 'I should see the task status for merge request "MR-task-open"' do
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
