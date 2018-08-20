module QaHelper
  # Define a data-qa attribute on the webpage
  #
  # Examples:
  #   qa('selector', 'username')
  #   qa('index', 1)
  #
  # Params:
  # +attr+:: the data-qa-* attribute where * is the attribute to match
  # +value+:: the value to set for data-qa-attr="value"
  def qa(attr, value)
    { "qa-#{attr}": value }
  end

  # Shortcut method(s) for QA
  #
  # Examples:
  #     data: qa_selector('test')
  #     data: qa_index(1)
  [:qa_selector].each do |qa_method|
    define_method qa_method do |pattern|
      qa("#{qa_method.to_s.split('_')[1]}", pattern)
    end
  end
end
