module SharedMarkdown
  include Spinach::DSL

  def header_should_have_correct_id_and_link(level, text, id, parent = ".wiki")
    find(:css, "#{parent} h#{level}##{id}").text.should == text
    find(:css, "#{parent} h#{level}##{id} > :last-child")[:href].should =~ /##{id}$/
  end

  step 'Header "Description header" should have correct id and link' do
    header_should_have_correct_id_and_link(1, 'Description header', 'description-header')
  end
end
