module SharedSnippet
  include Spinach::DSL

  step 'I have public "Personal snippet one" snippet' do
    create(:personal_snippet,
           title: "Personal snippet one",
           content: "Test content",
           file_name: "snippet.rb",
           visibility_level: Snippet::PUBLIC,
           author: current_user)
  end

  step 'I have private "Personal snippet private" snippet' do
    create(:personal_snippet,
           title: "Personal snippet private",
           content: "Provate content",
           file_name: "private_snippet.rb",
           visibility_level: Snippet::PRIVATE,
           author: current_user)
  end
  
  step 'I have internal "Personal snippet internal" snippet' do
    create(:personal_snippet,
           title: "Personal snippet internal",
           content: "Provate content",
           file_name: "internal_snippet.rb",
           visibility_level: Snippet::INTERNAL,
           author: current_user)
  end
  
  step 'I have a public many lined snippet' do
    create(:personal_snippet,
           title: 'Many lined snippet',
           content: <<-END.gsub(/^\s+\|/, ''),
             |line one
             |line two
             |line three
             |line four
             |line five
             |line six
             |line seven
             |line eight
             |line nine
             |line ten
             |line eleven
             |line twelve
             |line thirteen
             |line fourteen
           END
           file_name: 'many_lined_snippet.rb',
           visibility_level: Snippet::PUBLIC,
           author: current_user)
  end

  step 'There is public "Personal snippet one" snippet' do
    create(:personal_snippet,
           title: "Personal snippet one",
           content: "Test content",
           file_name: "snippet.rb",
           visibility_level: Snippet::PUBLIC,
           author: create(:user))
  end
end
