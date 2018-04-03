module SharedMarkdown
  include Spinach::DSL

  def header_should_have_correct_id_and_link(level, text, id, parent = ".wiki")
    node = find("#{parent} h#{level} a#user-content-#{id}")
    expect(node[:href]).to end_with "##{id}"

    # Work around a weird Capybara behavior where calling `parent` on a node
    # returns the whole document, not the node's actual parent element
    expect(find(:xpath, "#{node.path}/..").text).to eq text
  end

  step 'Header "Description header" should have correct id and link' do
    header_should_have_correct_id_and_link(1, 'Description header', 'description-header')
  end

  step 'I should not see the Markdown preview' do
    expect(find('.gfm-form .js-md-preview')).not_to be_visible
  end

  step 'I haven\'t written any description text' do
    find('.gfm-form').fill_in 'Description', with: ''
  end
end
