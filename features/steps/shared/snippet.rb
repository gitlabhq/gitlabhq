module SharedSnippet
  include Spinach::DSL

  And 'I have public "Personal snippet one" snippet' do
    create(:personal_snippet,
           title: "Personal snippet one",
           content: "Test content",
           file_name: "snippet.rb",
           private: false,
           author: current_user)
  end

  And 'I have private "Personal snippet private" snippet' do
    create(:personal_snippet,
           title: "Personal snippet private",
           content: "Provate content",
           file_name: "private_snippet.rb",
           private: true,
           author: current_user)
  end
end
